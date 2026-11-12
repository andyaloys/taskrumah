import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { DashboardService, AdminDashboard } from '../../../core/services/dashboard.service';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { DialogService } from '../../../core/services/dialog.service';
import { AssignmentStatus } from '../../../core/models/task-assignment.model';
import { WorshipService, AdminChildWorshipSummary, PrayerStatus } from '../../../core/services/worship.service';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './admin-dashboard.component.html'
})
export class AdminDashboardComponent implements OnInit {
  dashboard = signal<AdminDashboard | null>(null);
  loading = signal(true);
  currentWeekOffset = signal(0);
  today = new Date();
  tomorrow = new Date(Date.now() + 86400000);
  dayAfter = new Date(Date.now() + 2 * 86400000);
  selectedDate = signal<string>('');
  dateViewMode = signal<'today' | 'tomorrow' | 'dayAfter' | 'custom'>('today');

  // Worship Monitoring State
  worshipSummaries = signal<AdminChildWorshipSummary[]>([]);
  loadingWorship = signal(false);
  worshipDate = signal(new Date().toISOString().substring(0, 10));
  yesterdayDate = new Date(Date.now() - 24 * 60 * 60 * 1000);
  PrayerStatus = PrayerStatus;

  constructor(
    private dashboardService: DashboardService,
    private assignmentService: TaskAssignmentService,
    private worshipService: WorshipService,
    private dialog: DialogService
  ) {}

  ngOnInit() {
    this.loadDashboard();
    this.loadWorshipSummary();
  }

  formatDate(d: Date | string): string {
    const date = new Date(d);
    return date.toISOString().slice(0, 10);
  }

  selectDateMode(mode: 'today' | 'tomorrow' | 'dayAfter' | 'custom', customDate?: string) {
    this.dateViewMode.set(mode);
    if (mode === 'today') {
      this.selectedDate.set('');
      this.currentWeekOffset.set(0);
    } else if (mode === 'tomorrow') {
      this.selectedDate.set(this.formatDate(this.tomorrow));
      this.currentWeekOffset.set(0);
    } else if (mode === 'dayAfter') {
      this.selectedDate.set(this.formatDate(this.dayAfter));
      this.currentWeekOffset.set(0);
    } else if (mode === 'custom' && customDate) {
      this.selectedDate.set(customDate);
      this.currentWeekOffset.set(0);
    }
    this.loadDashboard();
  }

  onCustomDateChange(event: Event) {
    const val = (event.target as HTMLInputElement).value;
    if (val) {
      this.selectDateMode('custom', val);
    }
  }

  isFutureDate(): boolean {
    if (!this.selectedDate()) return false;
    const today = new Date();
    const todayDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const sel = new Date(this.selectedDate());
    return sel > todayDate;
  }

  loadDashboard() {
    this.loading.set(true);
    this.dashboardService.getAdminDashboard(this.currentWeekOffset(), this.selectedDate() || undefined).subscribe({
      next: (data) => { this.dashboard.set(data); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }

  changeWeek(delta: number) {
    this.selectedDate.set('');
    this.dateViewMode.set('today');
    this.currentWeekOffset.update(w => w + delta);
    this.loadDashboard();
  }

  setWeek(offset: number) {
    this.selectedDate.set('');
    this.dateViewMode.set('today');
    this.currentWeekOffset.set(offset);
    this.loadDashboard();
  }

  abs(val: number): number {
    return Math.abs(val);
  }

  canModify(dueDate: string | Date): boolean {
    if (!dueDate) return false;
    const due = new Date(dueDate);
    const dueDateOnly = new Date(due.getFullYear(), due.getMonth(), due.getDate());
    const today = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    return dueDateOnly >= yesterday;
  }

  approve(assignmentId: string) {
    this.assignmentService.approveTask(assignmentId).subscribe({
      next: () => {
        this.loadDashboard();
        this.dialog.success('Tugas berhasil disetujui! Poin telah ditambahkan ke anak.');
      },
      error: (err) => this.dialog.error('Gagal menyetujui: ' + (err.error?.message || 'Error'))
    });
  }

  async reject(assignmentId: string) {
    const reason = await this.dialog.prompt({
      title: 'Tolak Tugas?',
      message: 'Masukkan catatan/alasan penolakan untuk anak (opsional):',
      placeholder: 'Contoh: Belum selesai atau kurang rapi',
      confirmText: 'Tolak Tugas',
      cancelText: 'Batal',
      type: 'danger',
      icon: '❌'
    });

    if (reason === null) return; // User cancelled

    this.assignmentService.rejectTask(assignmentId, reason || undefined).subscribe({
      next: () => {
        this.loadDashboard();
        this.dialog.info('Tugas ditolak.');
      },
      error: (err) => this.dialog.error('Gagal menolak: ' + (err.error?.message || 'Error'))
    });
  }

  getStatusClass(status: AssignmentStatus): string {
    const classes: Record<AssignmentStatus, string> = {
      [AssignmentStatus.Pending]: 'bg-amber-50 text-amber-700 border border-amber-200/80',
      [AssignmentStatus.Submitted]: 'bg-sky-50 text-sky-700 border border-sky-200/80',
      [AssignmentStatus.Approved]: 'bg-emerald-50 text-emerald-700 border border-emerald-200/80',
      [AssignmentStatus.Rejected]: 'bg-rose-50 text-rose-700 border border-rose-200/80',
      [AssignmentStatus.Late]: 'bg-slate-100 text-slate-600 border border-slate-200/80',
    };
    return classes[status] || 'bg-slate-100 text-slate-700 border border-slate-200/80';
  }

  getStatusLabel(status: AssignmentStatus): string {
    const labels: Record<AssignmentStatus, string> = {
      [AssignmentStatus.Pending]: 'Menunggu',
      [AssignmentStatus.Submitted]: 'Terkirim',
      [AssignmentStatus.Approved]: 'Disetujui',
      [AssignmentStatus.Rejected]: 'Ditolak',
      [AssignmentStatus.Late]: 'Terlambat',
    };
    return labels[status] || status;
  }

  getProgressPercent(completed: number, total: number): number {
    if (total === 0) return 0;
    return Math.round((completed / total) * 100);
  }

  AssignmentStatus = AssignmentStatus;

  loadWorshipSummary() {
    this.loadingWorship.set(true);
    this.worshipService.getAdminSummary(this.worshipDate()).subscribe({
      next: (data) => {
        this.worshipSummaries.set(data);
        this.loadingWorship.set(false);
      },
      error: () => this.loadingWorship.set(false)
    });
  }

  onWorshipDateChange(ev: Event) {
    const val = (ev.target as HTMLInputElement).value;
    if (val) {
      this.worshipDate.set(val);
      this.loadWorshipSummary();
    }
  }

  setWorshipDatePreset(mode: 'today' | 'yesterday') {
    const d = new Date();
    if (mode === 'yesterday') d.setDate(d.getDate() - 1);
    this.worshipDate.set(d.toISOString().substring(0, 10));
    this.loadWorshipSummary();
  }

  getPrayerLabel(status: PrayerStatus | string): string {
    if (status === PrayerStatus.Mosque) return '+5p';
    if (status === PrayerStatus.Solo) return '+3p';
    return 'Belum';
  }

  getPrayerClass(status: PrayerStatus | string): string {
    if (status === PrayerStatus.Mosque) {
      return 'bg-emerald-600 text-white border-emerald-700 shadow-2xs font-extrabold';
    }
    if (status === PrayerStatus.Solo) {
      return 'bg-emerald-500 text-white border-emerald-600 shadow-2xs font-extrabold';
    }
    return 'bg-slate-100 text-slate-400 border-slate-200 font-medium';
  }

  getPrayerIcon(status: PrayerStatus | string): string {
    if (status === PrayerStatus.Mosque) return '🕌';
    if (status === PrayerStatus.Solo) return '🏫';
    return '⏳';
  }

  getPrayerCardClass(status: PrayerStatus | string): string {
    if (status === PrayerStatus.Mosque || status === PrayerStatus.Solo) {
      return 'border-emerald-300 bg-emerald-50/50 shadow-2xs';
    }
    return 'border-slate-100 bg-slate-50/70';
  }
}
