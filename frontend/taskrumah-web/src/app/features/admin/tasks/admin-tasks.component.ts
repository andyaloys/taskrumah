import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TaskService } from '../../../core/services/task.service';
import { UserService } from '../../../core/services/user.service';
import { DialogService } from '../../../core/services/dialog.service';
import { WorshipService, WorshipSetting, AdminChildWorshipSummary, PrayerStatus } from '../../../core/services/worship.service';
import { ChoreTask, TaskType } from '../../../core/models/task.model';
import { User } from '../../../core/models/user.model';

@Component({
  selector: 'app-admin-tasks',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './admin-tasks.component.html'
})
export class AdminTasksComponent implements OnInit {
  activeTab = signal<'tasks' | 'worship'>('tasks');
  PrayerStatus = PrayerStatus;

  // Task state
  tasks = signal<ChoreTask[]>([]);
  children = signal<User[]>([]);
  loading = signal(true);
  showForm = signal(false);
  editingTask = signal<ChoreTask | null>(null);
  form: FormGroup;
  TaskType = TaskType;
  saving = signal(false);

  // Day options for SpecificDays
  daysList = [
    { id: '1', label: 'Senin' },
    { id: '2', label: 'Selasa' },
    { id: '3', label: 'Rabu' },
    { id: '4', label: 'Kamis' },
    { id: '5', label: 'Jumat' },
    { id: '6', label: 'Sabtu' },
    { id: '7', label: 'Minggu' }
  ];
  selectedDays = signal<string[]>([]);

  // Re-assign modal state
  showAssignModal = signal(false);
  assigningTask = signal<ChoreTask | null>(null);
  assignChildId = signal('');
  assignDueDate = signal(new Date().toISOString().substring(0, 10));
  isAssigning = signal(false);

  // Worship Tab state
  worshipForm: FormGroup;
  worshipSetting = signal<WorshipSetting | null>(null);
  savingWorshipSetting = signal(false);
  worshipDate = signal(new Date().toISOString().substring(0, 10));
  worshipSummaries = signal<AdminChildWorshipSummary[]>([]);
  loadingWorship = signal(false);

  emojiOptions = [
    // Olahraga & Aktivitas Fisik
    '🏃', '🚴', '⚽', '🏀', '🏸', '🧘', '🏊', '🤸',
    // Ibadah Sholat & Doa
    '🕌', '🤲', '📿', '🛐', '📖',
    // Bangun Tidur & Rutinitas Pagi/Malam
    '⏰', '🌅', '🥱', '🛌', '🌄', '☀️', '🌙',
    // Pintu & Keamanan Rumah
    '🚪', '🔐', '🔒', '🔑',
    // Kebersihan & Rumah Tangga
    '🧹', '🌱', '📚', '🍽️', '🛏️', '🚾', '🗑️', '🛒', '🧺', '🧼', '🍳', '🧴',
    // Lain-lain & Belajar
    '🐕', '🐱', '🎒', '✏️', '💻', '✅'
  ];

  constructor(
    private taskService: TaskService,
    private userService: UserService,
    private worshipService: WorshipService,
    private fb: FormBuilder,
    private dialog: DialogService
  ) {
    this.form = this.fb.group({
      title: ['', Validators.required],
      description: [''],
      taskType: [TaskType.Daily, Validators.required],
      assignedToId: [''],
      points: [10, [Validators.required, Validators.min(1)]],
      iconEmoji: ['✅', Validators.required],
      dueDate: [new Date().toISOString().substring(0, 10)]
    });

    this.worshipForm = this.fb.group({
      soloPoints: [3, [Validators.required, Validators.min(0)]],
      mosquePoints: [5, [Validators.required, Validators.min(0)]],
      quranPoints: [5, [Validators.required, Validators.min(0)]]
    });
  }

  ngOnInit() {
    this.loadData();
  }

  loadData() {
    this.loading.set(true);
    this.taskService.getTasks(false).subscribe(tasks => {
      this.tasks.set(tasks);
      this.loading.set(false);
    });
    this.userService.getChildren().subscribe(c => this.children.set(c));
  }

  switchToWorshipTab() {
    this.activeTab.set('worship');
    this.loadWorshipSetting();
    this.loadWorshipSummary();
  }

  loadWorshipSetting() {
    this.worshipService.getSetting().subscribe({
      next: (s) => {
        this.worshipSetting.set(s);
        this.worshipForm.patchValue({
          soloPoints: s.soloPoints,
          mosquePoints: s.mosquePoints,
          quranPoints: s.quranPoints
        });
      }
    });
  }

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

  saveWorshipSetting() {
    if (this.worshipForm.invalid || this.savingWorshipSetting()) return;
    this.savingWorshipSetting.set(true);
    this.worshipService.updateSetting(this.worshipForm.value).subscribe({
      next: (s) => {
        this.savingWorshipSetting.set(false);
        this.worshipSetting.set(s);
        this.dialog.success('Pengaturan poin ibadah berhasil disimpan!');
      },
      error: () => {
        this.savingWorshipSetting.set(false);
        this.dialog.error('Gagal menyimpan pengaturan poin ibadah.');
      }
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

  openCreate() {
    this.editingTask.set(null);
    this.selectedDays.set([]);
    this.form.reset({
      taskType: TaskType.Daily,
      points: 10,
      iconEmoji: '✅',
      dueDate: new Date().toISOString().substring(0, 10)
    });
    this.showForm.set(true);
  }

  openEdit(task: ChoreTask) {
    this.editingTask.set(task);
    this.selectedDays.set(task.daysOfWeek ? task.daysOfWeek.split(',') : []);
    this.form.patchValue({
      title: task.title,
      description: task.description,
      taskType: task.taskType,
      assignedToId: task.assignedToId || '',
      points: task.points,
      iconEmoji: task.iconEmoji || '✅',
      dueDate: new Date().toISOString().substring(0, 10)
    });
    this.showForm.set(true);
  }

  toggleDay(dayId: string) {
    const current = [...this.selectedDays()];
    const idx = current.indexOf(dayId);
    if (idx >= 0) {
      current.splice(idx, 1);
    } else {
      current.push(dayId);
    }
    this.selectedDays.set(current);
  }

  getScheduleLabel(task: ChoreTask): string {
    if (task.taskType === TaskType.Daily) return 'Rutin Setiap Hari';
    if (task.taskType === TaskType.OneTime) return 'Sekali Saja';
    if (task.taskType === TaskType.SpecificDays && task.daysOfWeek) {
      const dayMap: { [k: string]: string } = {
        '1': 'Sen', '2': 'Sel', '3': 'Rab', '4': 'Kam', '5': 'Jum', '6': 'Sab', '7': 'Min'
      };
      const days = task.daysOfWeek.split(',').map(d => dayMap[d] || d);
      return days.join(', ');
    }
    return 'Hari Tertentu';
  }

  save() {
    if (this.saving() || this.form.invalid) return;

    const val = this.form.value;
    const taskType: TaskType = val.taskType;

    if (taskType === TaskType.SpecificDays && this.selectedDays().length === 0) {
      this.dialog.error('Pilih minimal 1 hari pelaksanaan untuk jadwal hari tertentu!');
      return;
    }

    this.saving.set(true);

    const payload = {
      title: val.title,
      description: val.description,
      taskType: taskType,
      daysOfWeek: taskType === TaskType.SpecificDays ? this.selectedDays().sort().join(',') : undefined,
      assignedToId: val.assignedToId || null,
      points: val.points,
      iconEmoji: val.iconEmoji,
      dueDate: taskType === TaskType.OneTime ? val.dueDate : undefined
    };

    const task = this.editingTask();
    if (task) {
      this.taskService.updateTask(task.id, payload).subscribe({
        next: () => {
          this.saving.set(false);
          this.showForm.set(false);
          this.loadData();
          this.dialog.success('Tugas berhasil diperbarui!');
        },
        error: (err) => {
          this.saving.set(false);
          this.dialog.error('Gagal memperbarui: ' + (err.error?.message || 'Error'));
        }
      });
    } else {
      this.taskService.createTask(payload).subscribe({
        next: () => {
          this.saving.set(false);
          this.showForm.set(false);
          this.loadData();
          this.dialog.success('Tugas baru berhasil dibuat!');
        },
        error: (err) => {
          this.saving.set(false);
          this.dialog.error('Gagal membuat tugas: ' + (err.error?.message || 'Error'));
        }
      });
    }
  }

  openAssignModal(task: ChoreTask) {
    this.assigningTask.set(task);
    this.assignChildId.set(task.assignedToId || '');
    this.assignDueDate.set(new Date().toISOString().substring(0, 10));
    this.showAssignModal.set(true);
  }

  submitAssign() {
    const task = this.assigningTask();
    if (!task) return;
    this.isAssigning.set(true);

    this.taskService.assignTask(task.id, {
      assignedToId: this.assignChildId() || undefined,
      dueDate: this.assignDueDate()
    }).subscribe({
      next: () => {
        this.isAssigning.set(false);
        this.showAssignModal.set(false);
        this.dialog.success(`Tugas '${task.title}' berhasil ditugaskan!`);
      },
      error: (err) => {
        this.isAssigning.set(false);
        this.dialog.error('Gagal menugaskan: ' + (err.error?.message || 'Error'));
      }
    });
  }

  toggleActive(task: ChoreTask) {
    this.taskService.updateTask(task.id, { isActive: !task.isActive }).subscribe(() => this.loadData());
  }

  selectEmoji(emoji: string) {
    this.form.patchValue({ iconEmoji: emoji });
  }

  getPrayerLabel(status: PrayerStatus | string): string {
    if (status === PrayerStatus.Mosque) return 'Masjid';
    if (status === PrayerStatus.Solo) return 'Sendiri / Sekolah';
    return 'Belum / Tidak';
  }

  getPrayerClass(status: PrayerStatus | string): string {
    if (status === PrayerStatus.Mosque) return 'bg-emerald-50 text-emerald-700 border-emerald-200';
    if (status === PrayerStatus.Solo) return 'bg-sky-50 text-sky-700 border-sky-200';
    return 'bg-slate-100 text-slate-400 border-slate-200';
  }

  getPrayerIcon(status: PrayerStatus | string): string {
    if (status === PrayerStatus.Mosque) return '🕌';
    if (status === PrayerStatus.Solo) return '🏫';
    return '⚪';
  }
}
