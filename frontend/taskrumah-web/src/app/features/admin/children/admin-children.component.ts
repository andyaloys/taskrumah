import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserService } from '../../../core/services/user.service';
import { User } from '../../../core/models/user.model';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { TaskAssignment, AssignmentStatus } from '../../../core/models/task-assignment.model';
import { DialogService } from '../../../core/services/dialog.service';

@Component({
  selector: 'app-admin-children',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './admin-children.component.html'
})
export class AdminChildrenComponent implements OnInit {
  children = signal<User[]>([]);
  selectedChild = signal<User | null>(null);
  assignments = signal<TaskAssignment[]>([]);
  loading = signal(true);
  AssignmentStatus = AssignmentStatus;

  // Date filters: all, today, tomorrow, dayAfter, custom
  activeDateFilter = signal<'today' | 'tomorrow' | 'dayAfter' | 'custom' | 'all'>('all');
  selectedDate = signal<string>('');
  today = new Date();
  tomorrow = new Date(Date.now() + 86400000);
  dayAfter = new Date(Date.now() + 2 * 86400000);

  // Edit child modal state
  isEditing = signal(false);
  isSaving = signal(false);
  editingChild = signal<User | null>(null);
  editName = signal('');

  constructor(
    private userService: UserService,
    private assignmentService: TaskAssignmentService,
    private dialog: DialogService
  ) {}

  ngOnInit() {
    this.loadChildren();
  }

  formatDate(d: Date | string): string {
    const date = new Date(d);
    return date.toISOString().slice(0, 10);
  }

  setDateFilter(filter: 'today' | 'tomorrow' | 'dayAfter' | 'custom' | 'all', customDate?: string) {
    this.activeDateFilter.set(filter);
    if (filter === 'all') {
      this.selectedDate.set('');
    } else if (filter === 'today') {
      this.selectedDate.set(this.formatDate(this.today));
    } else if (filter === 'tomorrow') {
      this.selectedDate.set(this.formatDate(this.tomorrow));
    } else if (filter === 'dayAfter') {
      this.selectedDate.set(this.formatDate(this.dayAfter));
    } else if (filter === 'custom' && customDate) {
      this.selectedDate.set(customDate);
    }
    this.loadChildAssignments();
  }

  onCustomDateChange(event: Event) {
    const val = (event.target as HTMLInputElement).value;
    if (val) {
      this.setDateFilter('custom', val);
    }
  }

  isFuture(): boolean {
    if (this.activeDateFilter() === 'all') return false;
    const sel = new Date(this.selectedDate() || this.today);
    const todayDate = new Date(this.today.getFullYear(), this.today.getMonth(), this.today.getDate());
    return sel > todayDate;
  }

  loadChildren() {
    this.userService.getChildren().subscribe(c => {
      this.children.set(c);
      this.loading.set(false);
      // auto select first child if none selected
      if (!this.selectedChild() && c.length > 0) {
        this.selectChild(c[0]);
      } else if (this.selectedChild()) {
        const updated = c.find(item => item.id === this.selectedChild()!.id);
        if (updated) this.selectedChild.set(updated);
      }
    });
  }

  loadChildAssignments() {
    const child = this.selectedChild();
    if (!child) return;

    if (this.activeDateFilter() === 'all') {
      this.assignmentService.getAssignments({ userId: child.id }).subscribe(a => this.assignments.set(a));
    } else {
      const dateToFetch = this.selectedDate() || this.formatDate(this.today);
      this.assignmentService.getSchedule(dateToFetch, child.id).subscribe(a => this.assignments.set(a));
    }
  }

  selectChild(child: User) {
    this.selectedChild.set(child);
    this.loadChildAssignments();
  }

  canModify(dueDate: string | Date): boolean {
    if (!dueDate) return false;
    const due = new Date(dueDate);
    const dueDateOnly = new Date(due.getFullYear(), due.getMonth(), due.getDate());
    const today = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    return dueDateOnly >= yesterday;
  }

  quickApprove(a: TaskAssignment) {
    this.assignmentService.updateStatus(a.id, AssignmentStatus.Approved).subscribe({
      next: () => {
        this.loadChildren();
        if (this.selectedChild()) this.selectChild(this.selectedChild()!);
        this.dialog.success(`Tugas '${a.taskTitle}' disetujui! Poin ditambahkan.`);
      },
      error: (err) => this.dialog.error('Gagal menyetujui: ' + (err.error?.message || 'Error'))
    });
  }

  async quickReject(a: TaskAssignment) {
    const reason = await this.dialog.prompt({
      title: 'Tolak Tugas?',
      message: `Tolak tugas "${a.taskTitle}"?\nMasukkan catatan/alasan penolakan untuk anak:`,
      placeholder: 'Contoh: Belum bersih, rapikan lagi ya',
      confirmText: 'Tolak Tugas',
      cancelText: 'Batal',
      type: 'danger',
      icon: '❌'
    });

    if (reason === null) return; // User clicked Cancel

    this.assignmentService.updateStatus(a.id, AssignmentStatus.Rejected, reason || undefined).subscribe({
      next: () => {
        this.loadChildren();
        if (this.selectedChild()) this.selectChild(this.selectedChild()!);
        this.dialog.info(`Tugas '${a.taskTitle}' ditolak.`);
      },
      error: (err) => this.dialog.error('Gagal menolak: ' + (err.error?.message || 'Error'))
    });
  }

  quickReset(a: TaskAssignment) {
    this.assignmentService.updateStatus(a.id, AssignmentStatus.Pending).subscribe({
      next: () => {
        this.loadChildren();
        if (this.selectedChild()) this.selectChild(this.selectedChild()!);
        this.dialog.info(`Status tugas '${a.taskTitle}' direset ke Menunggu.`);
      },
      error: (err) => this.dialog.error('Gagal reset: ' + (err.error?.message || 'Error'))
    });
  }

  openEditModal(child: User, event: Event) {
    event.stopPropagation();
    this.editingChild.set(child);
    this.editName.set(child.name);
    this.isEditing.set(true);
  }

  closeEditModal() {
    this.isEditing.set(false);
    this.editingChild.set(null);
    this.editName.set('');
  }

  onNameInput(event: Event) {
    const target = event.target as HTMLInputElement;
    this.editName.set(target.value);
  }

  saveChildName() {
    const child = this.editingChild();
    const newName = this.editName().trim();
    if (!child || !newName) return;

    this.isSaving.set(true);
    this.userService.updateUser(child.id, { name: newName }).subscribe({
      next: (updated) => {
        this.children.update(list => list.map(c => c.id === child.id ? { ...c, name: updated.name } : c));
        if (this.selectedChild()?.id === child.id) {
          this.selectedChild.update(c => c ? { ...c, name: updated.name } : null);
        }
        this.isSaving.set(false);
        this.closeEditModal();
        this.dialog.success(`Nama berhasil diubah menjadi '${updated.name}'`);
      },
      error: () => {
        this.isSaving.set(false);
        this.dialog.error('Gagal memperbarui nama anak.');
      }
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
}
