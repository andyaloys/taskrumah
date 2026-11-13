import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TaskService, TaskAssignmentService } from '../../../core/services/task.service';
import { DialogService } from '../../../core/services/dialog.service';
import { ChoreTask } from '../../../core/models/task.model';
import { TaskAssignment, AssignmentStatus } from '../../../core/models/task-assignment.model';
import { AuthService } from '../../../core/auth/auth.service';
import { formatLocalDate } from '../../../core/utils/date-utils';

@Component({
  selector: 'app-my-tasks',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './my-tasks.component.html'
})
export class MyTasksComponent implements OnInit {
  assignments = signal<TaskAssignment[]>([]);
  todayAssignments = signal<TaskAssignment[]>([]);
  yesterdayAssignments = signal<TaskAssignment[]>([]);
  tomorrowAssignments = signal<TaskAssignment[]>([]);
  customDateAssignments = signal<TaskAssignment[]>([]);
  
  loading = signal(true);
  loadingCustom = signal(false);
  
  activeView = signal<'today' | 'yesterday' | 'tomorrow' | 'date' | 'all'>('today');
  filter = signal<AssignmentStatus | 'All'>('All');
  AssignmentStatus = AssignmentStatus;

  today: Date;
  yesterday: Date;
  tomorrow: Date;
  selectedDate = signal<string>('');

  // Extra Task Modal State
  showExtraModal = signal(false);
  extraTasks = signal<ChoreTask[]>([]);
  loadingExtra = signal(false);
  selectedExtraTaskId = signal('');
  extraNote = signal('');
  extraPhoto: File | null = null;
  extraPhotoPreview: string | null = null;
  extraCompressionInfo = signal('');
  extraCompressing = signal(false);
  submittingExtra = signal(false);

  constructor(
    private taskService: TaskService,
    private assignmentService: TaskAssignmentService,
    private auth: AuthService,
    private dialog: DialogService,
    private route: ActivatedRoute
  ) {
    const now = new Date();
    this.today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    this.yesterday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
    this.tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    this.selectedDate.set(this.formatLocalDate(this.today));
  }

  ngOnInit() {
    this.loadAll();

    // Check if queryParam ?extra=true is passed
    this.route.queryParamMap.subscribe(params => {
      if (params.get('extra') === 'true') {
        this.openExtraTaskModal();
      }
    });
  }

  formatLocalDate(d: Date | string): string {
    const date = new Date(d);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  loadAll() {
    this.loading.set(true);

    // 1. All assignments (for history)
    this.assignmentService.getAssignments().subscribe({
      next: (data) => {
        this.assignments.set(data);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });

    // 2. Today's schedule
    const todayStr = this.formatLocalDate(this.today);
    this.assignmentService.getSchedule(todayStr).subscribe({
      next: (data) => this.todayAssignments.set(data),
      error: () => {}
    });

    // 3. Yesterday's schedule (can still be modified/submitted if missed)
    const yesterdayStr = this.formatLocalDate(this.yesterday);
    this.assignmentService.getSchedule(yesterdayStr).subscribe({
      next: (data) => this.yesterdayAssignments.set(data),
      error: () => {}
    });

    // 4. Tomorrow's schedule
    const tomorrowStr = this.formatLocalDate(this.tomorrow);
    this.assignmentService.getSchedule(tomorrowStr).subscribe({
      next: (data) => this.tomorrowAssignments.set(data),
      error: () => {}
    });
  }

  setView(view: 'today' | 'yesterday' | 'tomorrow' | 'date' | 'all') {
    this.activeView.set(view);
    if (view === 'date' && this.customDateAssignments().length === 0) {
      this.loadCustomDate(this.selectedDate());
    }
  }

  onDateSelect(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.value) {
      this.selectedDate.set(input.value);
      this.loadCustomDate(input.value);
    }
  }

  stepCustomDate(daysDelta: number) {
    const current = new Date(this.selectedDate() + 'T00:00:00');
    current.setDate(current.getDate() + daysDelta);
    const newStr = this.formatLocalDate(current);
    this.selectedDate.set(newStr);
    this.loadCustomDate(newStr);
  }

  loadCustomDate(dateStr: string) {
    this.loadingCustom.set(true);
    this.assignmentService.getSchedule(dateStr).subscribe({
      next: (data) => {
        this.customDateAssignments.set(data);
        this.loadingCustom.set(false);
      },
      error: () => this.loadingCustom.set(false)
    });
  }

  yesterdayPendingCount(): number {
    return this.yesterdayAssignments().filter(t =>
      t.status === AssignmentStatus.Pending ||
      t.status === AssignmentStatus.Late ||
      t.status === AssignmentStatus.Rejected
    ).length;
  }

  filteredTasks(): TaskAssignment[] {
    const view = this.activeView();
    if (view === 'today') {
      return this.todayAssignments();
    }
    if (view === 'yesterday') {
      return this.yesterdayAssignments();
    }
    if (view === 'tomorrow') {
      return this.tomorrowAssignments();
    }
    if (view === 'date') {
      return this.customDateAssignments();
    }
    const f = this.filter();
    if (f === 'All') return this.assignments();
    return this.assignments().filter(a => a.status === f);
  }

  private getDueDateOnly(dueDate: string | Date): Date {
    if (!dueDate) return new Date();
    const dateStr = formatLocalDate(dueDate);
    const [y, m, d] = dateStr.split('-').map(Number);
    return new Date(y, m - 1, d);
  }

  canModify(dueDate: string | Date): boolean {
    if (!dueDate) return false;
    const dueDateOnly = this.getDueDateOnly(dueDate);
    const today = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    return dueDateOnly >= yesterday;
  }

  isPastDate(dueDate: string | Date): boolean {
    if (!dueDate) return false;
    const dueDateOnly = this.getDueDateOnly(dueDate);
    const today = new Date();
    const todayOnly = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    return dueDateOnly < todayOnly;
  }

  isFutureDate(dueDate: string | Date): boolean {
    if (!dueDate) return false;
    const dueDateOnly = this.getDueDateOnly(dueDate);
    const today = new Date();
    const todayOnly = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    return dueDateOnly > todayOnly;
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

  getSubmitTaskId(task: TaskAssignment): string {
    if (task.id && task.id !== '00000000-0000-0000-0000-000000000000') {
      return task.id;
    }
    return task.taskId;
  }

  // --- Extra Task (Tugas Tambahan) Methods ---

  openExtraTaskModal() {
    this.selectedExtraTaskId.set('');
    this.extraNote.set('');
    this.extraPhoto = null;
    this.extraPhotoPreview = null;
    this.extraCompressionInfo.set('');
    this.showExtraModal.set(true);
    this.loadExtraTasks();
  }

  closeExtraModal() {
    this.showExtraModal.set(false);
  }

  loadExtraTasks() {
    this.loadingExtra.set(true);
    this.taskService.getExtraTasks().subscribe({
      next: (tasks) => {
        this.extraTasks.set(tasks);
        this.loadingExtra.set(false);
        if (tasks.length > 0 && !this.selectedExtraTaskId()) {
          this.selectedExtraTaskId.set(tasks[0].id);
        }
      },
      error: () => {
        this.loadingExtra.set(false);
        this.dialog.error('Gagal memuat daftar tugas tambahan.');
      }
    });
  }

  getSelectedExtraTask(): ChoreTask | undefined {
    return this.extraTasks().find(t => t.id === this.selectedExtraTaskId());
  }

  async onExtraPhotoSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files?.[0]) {
      const rawFile = input.files[0];
      const origSize = (rawFile.size / 1024).toFixed(0);

      this.extraCompressing.set(true);
      try {
        const compressed = await this.compressImage(rawFile, 1280, 1280, 0.75);
        this.extraPhoto = compressed;
        const newSize = (compressed.size / 1024).toFixed(0);
        if (compressed.size < rawFile.size) {
          const savedPct = Math.round((1 - (compressed.size / rawFile.size)) * 100);
          this.extraCompressionInfo.set(`${origSize} KB ➔ ${newSize} KB (-${savedPct}%)`);
        } else {
          this.extraCompressionInfo.set(`${newSize} KB`);
        }

        const reader = new FileReader();
        reader.onload = (e) => this.extraPhotoPreview = e.target?.result as string;
        reader.readAsDataURL(compressed);
      } catch {
        this.extraPhoto = rawFile;
        this.extraCompressionInfo.set(`${origSize} KB`);
        const reader = new FileReader();
        reader.onload = (e) => this.extraPhotoPreview = e.target?.result as string;
        reader.readAsDataURL(rawFile);
      } finally {
        this.extraCompressing.set(false);
      }
    }
  }

  removeExtraPhoto() {
    this.extraPhoto = null;
    this.extraPhotoPreview = null;
    this.extraCompressionInfo.set('');
  }

  submitExtraTask() {
    const taskId = this.selectedExtraTaskId();
    if (!taskId) {
      this.dialog.error('Silakan pilih tugas tambahan terlebih dahulu!');
      return;
    }

    this.submittingExtra.set(true);
    this.assignmentService.submitExtraTask(
      taskId,
      this.extraNote() || undefined,
      this.extraPhoto || undefined
    ).subscribe({
      next: () => {
        this.submittingExtra.set(false);
        this.showExtraModal.set(false);
        this.dialog.success('Tugas tambahan berhasil dilaporkan! Menunggu persetujuan orang tua.');
        this.loadAll();
      },
      error: (err) => {
        this.submittingExtra.set(false);
        this.dialog.error('Gagal melaporkan tugas: ' + (err.error?.message || 'Terjadi kesalahan'));
      }
    });
  }

  private compressImage(file: File, maxWidth: number, maxHeight: number, quality: number): Promise<File> {
    return new Promise((resolve) => {
      if (!file.type.startsWith('image/')) {
        resolve(file);
        return;
      }
      const reader = new FileReader();
      reader.onload = (event) => {
        const img = new Image();
        img.onload = () => {
          let width = img.width;
          let height = img.height;

          if (width > maxWidth || height > maxHeight) {
            if (width > height) {
              height = Math.round((height * maxWidth) / width);
              width = maxWidth;
            } else {
              width = Math.round((width * maxHeight) / height);
              height = maxHeight;
            }
          }

          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            resolve(file);
            return;
          }

          ctx.drawImage(img, 0, 0, width, height);
          canvas.toBlob(
            (blob) => {
              if (!blob || blob.size >= file.size) {
                resolve(file);
              } else {
                const cleanName = file.name.replace(/\.[^/.]+$/, '') + '.jpg';
                const compressedFile = new File([blob], cleanName, {
                  type: 'image/jpeg',
                  lastModified: Date.now(),
                });
                resolve(compressedFile);
              }
            },
            'image/jpeg',
            quality
          );
        };
        img.onerror = () => resolve(file);
        img.src = event.target?.result as string;
      };
      reader.onerror = () => resolve(file);
      reader.readAsDataURL(file);
    });
  }
}
