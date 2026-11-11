import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { WorshipService, DailyWorship, WorshipSetting, PrayerStatus } from '../../../core/services/worship.service';
import { DialogService } from '../../../core/services/dialog.service';
import { AuthService } from '../../../core/auth/auth.service';

interface PrayerItem {
  key: 'subuh' | 'dzuhur' | 'ashar' | 'maghrib' | 'isya';
  name: string;
  emoji: string;
  timeInfo: string;
}

@Component({
  selector: 'app-child-worship',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './child-worship.component.html'
})
export class ChildWorshipComponent implements OnInit {
  PrayerStatus = PrayerStatus;
  setting = signal<WorshipSetting>({
    id: '',
    soloPoints: 3,
    mosquePoints: 5,
    quranPoints: 5,
    updatedAt: ''
  });

  selectedDate = signal<string>(this.formatDate(new Date()));
  dateViewMode = signal<'today' | 'yesterday'>('today');
  today = new Date();
  yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
  loading = signal(true);
  saving = signal(false);

  record = signal<DailyWorship>({
    id: '',
    userId: '',
    date: '',
    subuh: PrayerStatus.None,
    dzuhur: PrayerStatus.None,
    ashar: PrayerStatus.None,
    maghrib: PrayerStatus.None,
    isya: PrayerStatus.None,
    quranDone: false,
    quranNote: '',
    totalPointsEarned: 0,
    createdAt: '',
    updatedAt: ''
  });

  prayers: PrayerItem[] = [
    { key: 'subuh', name: 'Sholat Subuh', emoji: '🌅', timeInfo: 'Fajar / Subuh' },
    { key: 'dzuhur', name: 'Sholat Dzuhur', emoji: '☀️', timeInfo: 'Siang Hari' },
    { key: 'ashar', name: 'Sholat Ashar', emoji: '🌤️', timeInfo: 'Sore Hari' },
    { key: 'maghrib', name: 'Sholat Maghrib', emoji: '🌆', timeInfo: 'Petang / Maghrib' },
    { key: 'isya', name: 'Sholat Isya', emoji: '🌙', timeInfo: 'Malam Hari' }
  ];

  constructor(
    private worshipService: WorshipService,
    private dialog: DialogService,
    private auth: AuthService
  ) {}

  ngOnInit() {
    this.loadSetting();
    this.loadWorshipData();
  }

  formatDate(d: Date): string {
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  selectDay(mode: 'today' | 'yesterday') {
    this.dateViewMode.set(mode);
    const d = new Date();
    if (mode === 'yesterday') {
      d.setDate(d.getDate() - 1);
    }
    this.selectedDate.set(this.formatDate(d));
    this.loadWorshipData();
  }

  isReadOnly(): boolean {
    const sel = this.selectedDate();
    const today = this.formatDate(new Date());
    const yest = new Date();
    yest.setDate(yest.getDate() - 1);
    const yestStr = this.formatDate(yest);
    return sel !== today && sel !== yestStr;
  }

  loadSetting() {
    this.worshipService.getSetting().subscribe({
      next: (s) => this.setting.set(s)
    });
  }

  loadWorshipData() {
    this.loading.set(true);
    this.worshipService.getMyWorship(this.selectedDate()).subscribe({
      next: (data) => {
        this.record.set(data);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  setPrayerStatus(prayerKey: 'subuh' | 'dzuhur' | 'ashar' | 'maghrib' | 'isya', status: PrayerStatus) {
    if (this.isReadOnly()) {
      this.dialog.error('Data hari yang sudah lampau lebih dari 1 hari telah dikunci.');
      return;
    }

    const current = { ...this.record() };
    current[prayerKey] = status;
    this.record.set(current);
  }

  toggleQuran() {
    if (this.isReadOnly()) {
      this.dialog.error('Data hari yang sudah lampau lebih dari 1 hari telah dikunci.');
      return;
    }
    const current = { ...this.record() };
    current.quranDone = !current.quranDone;
    this.record.set(current);
  }

  save() {
    if (this.saving()) return;
    this.saving.set(true);

    const rec = this.record();
    this.worshipService.saveWorship({
      date: this.selectedDate(),
      subuh: rec.subuh,
      dzuhur: rec.dzuhur,
      ashar: rec.ashar,
      maghrib: rec.maghrib,
      isya: rec.isya,
      quranDone: rec.quranDone,
      quranNote: rec.quranNote
    }).subscribe({
      next: (res) => {
        this.saving.set(false);
        this.record.set(res.record);
        // Update user total points in auth state
        const user = this.auth.currentUser();
        if (user) {
          this.auth.currentUser.set({ ...user, totalPoints: res.userTotalPoints });
        }
        this.dialog.success('Alhamdulillah! Catatan ibadah berhasil disimpan 🎉');
      },
      error: (err) => {
        this.saving.set(false);
        this.dialog.error(err.error?.message || 'Gagal menyimpan catatan ibadah.');
      }
    });
  }

  calculateEstimatedPoints(): number {
    const rec = this.record();
    const set = this.setting();

    const getP = (st: PrayerStatus) => {
      if (st === PrayerStatus.Mosque) return set.mosquePoints;
      if (st === PrayerStatus.Solo) return set.soloPoints;
      return 0;
    };

    return getP(rec.subuh)
         + getP(rec.dzuhur)
         + getP(rec.ashar)
         + getP(rec.maghrib)
         + getP(rec.isya)
         + (rec.quranDone ? set.quranPoints : 0);
  }
}
