import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TaskService } from '../../../core/services/task.service';
import { UserService } from '../../../core/services/user.service';
import { DialogService } from '../../../core/services/dialog.service';
import { WorshipService, WorshipSetting } from '../../../core/services/worship.service';
import { ChoreTask, TaskType } from '../../../core/models/task.model';
import { User } from '../../../core/models/user.model';
import { getTodayDateString } from '../../../core/utils/date-utils';

@Component({
  selector: 'app-admin-tasks',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './admin-tasks.component.html'
})
export class AdminTasksComponent implements OnInit {
  activeTab = signal<'tasks' | 'worship'>('tasks');

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
  assignDueDate = signal(getTodayDateString());
  isAssigning = signal(false);

  // Worship Tab state
  worshipForm: FormGroup;
  worshipSetting = signal<WorshipSetting | null>(null);
  savingWorshipSetting = signal(false);

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
      targetTime: [''],
      dueDate: [getTodayDateString()]
    });

    this.worshipForm = this.fb.group({
      soloPoints: [3, [Validators.required, Validators.min(0)]],
      mosquePoints: [5, [Validators.required, Validators.min(0)]],
      quranPoints: [5, [Validators.required, Validators.min(0)]],
      reminderMinutesBeforeEnd: [30, [Validators.required, Validators.min(5), Validators.max(120)]],
      quranReminderTime: ['19:00', Validators.required]
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
  }

  loadWorshipSetting() {
    this.worshipService.getSetting().subscribe({
      next: (s) => {
        this.worshipSetting.set(s);
        this.worshipForm.patchValue({
          soloPoints: s.soloPoints,
          mosquePoints: s.mosquePoints,
          quranPoints: s.quranPoints,
          reminderMinutesBeforeEnd: s.reminderMinutesBeforeEnd ?? 30,
          quranReminderTime: s.quranReminderTime ?? '19:00'
        });
      }
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

  openCreate() {
    this.editingTask.set(null);
    this.selectedDays.set([]);
    this.form.reset({
      taskType: TaskType.Daily,
      points: 10,
      iconEmoji: '✅',
      targetTime: '',
      dueDate: getTodayDateString()
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
      targetTime: task.targetTime || '',
      dueDate: getTodayDateString()
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
    if (task.taskType === TaskType.OneTime) return 'Tugas Tambahan';
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
      targetTime: val.targetTime ? val.targetTime : undefined,
      dueDate: undefined
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
    this.assignDueDate.set(getTodayDateString());
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

  deleteTask(task: ChoreTask) {
    this.taskService.getTaskUsage(task.id).subscribe({
      next: (usage) => {
        let confirmMsg = '';
        if (usage.hasHistory) {
          confirmMsg = `⚠️ PERHATIAN: Tugas "${task.title}" SUDAH PERNAH DIGUNAKAN!\n\n` +
            `• Pernah diselesaikan anak: ${usage.completedAssignments} kali\n` +
            `• Total riwayat penugasan: ${usage.totalAssignments} kali\n\n` +
            `✅ Poin bintang anak yang sudah diperoleh TETAP AMAN dan TIDAK AKAN berkurang.\n` +
            `ℹ️ Namun catatan riwayat penugasan tugas ini akan ikut dihapus dari database.\n\n` +
            `💡 Tips: Jika hanya ingin menghentikan tugas ini agar tidak muncul lagi, Anda cukup memilih tombol 'Nonaktifkan'.\n\n` +
            `Apakah Anda TETAP YAKIN ingin menghapus tugas ini secara permanen?`;
        } else {
          confirmMsg = `Tugas "${task.title}" belum pernah dikerjakan oleh anak.\n\nApakah Anda yakin ingin menghapus tugas ini secara permanen?`;
        }

        if (!confirm(confirmMsg)) return;

        this.taskService.deleteTask(task.id).subscribe({
          next: () => {
            this.loadData();
          },
          error: (err) => {
            alert(err.error?.message || 'Gagal menghapus tugas');
          }
        });
      },
      error: () => {
        if (!confirm(`Apakah Anda yakin ingin menghapus tugas "${task.title}" secara permanen?`)) return;
        this.taskService.deleteTask(task.id).subscribe({
          next: () => this.loadData(),
          error: (err) => alert(err.error?.message || 'Gagal menghapus tugas')
        });
      }
    });
  }

  selectEmoji(emoji: string) {
    this.form.patchValue({ iconEmoji: emoji });
  }
}
