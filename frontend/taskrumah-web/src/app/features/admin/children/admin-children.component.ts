import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UserService } from '../../../core/services/user.service';
import { AuthService } from '../../../core/auth/auth.service';
import { User, UserRole } from '../../../core/models/user.model';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { TaskAssignment, AssignmentStatus } from '../../../core/models/task-assignment.model';
import { DialogService } from '../../../core/services/dialog.service';

@Component({
  selector: 'app-admin-children',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-children.component.html'
})
export class AdminChildrenComponent implements OnInit {
  UserRole = UserRole;
  AssignmentStatus = AssignmentStatus;

  // Active navigation tab: 'children' or 'parents'
  activeTab = signal<'children' | 'parents'>('children');

  allUsers = signal<User[]>([]);
  children = signal<User[]>([]);
  parents = signal<User[]>([]);
  selectedChild = signal<User | null>(null);
  assignments = signal<TaskAssignment[]>([]);
  loading = signal(true);

  // Uploading state
  uploadingUserId = signal<string | null>(null);

  // Date filters: all, today, tomorrow, dayAfter, custom
  activeDateFilter = signal<'today' | 'tomorrow' | 'dayAfter' | 'custom' | 'all'>('all');
  selectedDate = signal<string>('');
  today = new Date();
  tomorrow = new Date(Date.now() + 86400000);
  dayAfter = new Date(Date.now() + 2 * 86400000);

  // Edit user modal state
  isEditing = signal(false);
  isSaving = signal(false);
  editingUser = signal<User | null>(null);
  editName = signal('');
  editPassword = signal('');

  // Create user modal state
  isCreating = signal(false);
  newName = signal('');
  newEmail = signal('');
  newPassword = signal('');
  newRole = signal<UserRole>(UserRole.Child);

  constructor(
    public auth: AuthService,
    private userService: UserService,
    private assignmentService: TaskAssignmentService,
    private dialog: DialogService
  ) {}

  ngOnInit() {
    this.loadUsers();
  }

  formatDate(d: Date | string): string {
    const date = new Date(d);
    return date.toISOString().slice(0, 10);
  }

  loadUsers() {
    this.loading.set(true);
    this.userService.getUsers().subscribe({
      next: (users) => {
        this.allUsers.set(users);
        const activeChildren = users.filter(u => u.role === UserRole.Child && u.isActive);
        const activeParents = users.filter(u => u.role === UserRole.Admin && u.isActive);
        this.children.set(activeChildren);
        this.parents.set(activeParents);
        this.loading.set(false);

        // Select first child if none selected
        if (!this.selectedChild() && activeChildren.length > 0) {
          this.selectChild(activeChildren[0]);
        } else if (this.selectedChild()) {
          const updated = activeChildren.find(item => item.id === this.selectedChild()!.id);
          if (updated) this.selectedChild.set(updated);
        }
      },
      error: () => {
        this.loading.set(false);
        this.dialog.error('Gagal memuat data pengguna');
      }
    });
  }

  setActiveTab(tab: 'children' | 'parents') {
    this.activeTab.set(tab);
  }

  selectChild(child: User) {
    this.selectedChild.set(child);
    this.loadChildAssignments();
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

  canModify(dueDate: string | Date): boolean {
    if (!dueDate) return false;
    const due = new Date(dueDate);
    const dueDateOnly = new Date(due.getFullYear(), due.getMonth(), due.getDate());
    const today = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    return dueDateOnly >= yesterday;
  }

  // --- Avatar Upload Feature ---
  triggerAvatarUpload(inputElement: HTMLInputElement) {
    inputElement.click();
  }

  onAvatarFileSelected(event: Event, userId: string) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    if (file.size > 10 * 1024 * 1024) {
      this.dialog.error('Ukuran file foto maksimal 10MB');
      return;
    }

    this.uploadingUserId.set(userId);
    this.userService.uploadAvatar(userId, file).subscribe({
      next: (updatedUser) => {
        this.uploadingUserId.set(null);
        input.value = ''; // reset file input

        // Update list in place
        this.updateUserInLists(updatedUser);

        // If updated user is current logged in admin, update header profile
        if (this.auth.currentUser()?.userId === updatedUser.id) {
          this.auth.updateCurrentUserProfile({ avatarUrl: updatedUser.avatarUrl });
        }

        this.dialog.success(`Foto profil untuk ${updatedUser.name} berhasil diperbarui! 📸`);
      },
      error: (err) => {
        this.uploadingUserId.set(null);
        input.value = '';
        this.dialog.error('Gagal mengupload foto: ' + (err.error?.message || 'Terjadi kesalahan'));
      }
    });
  }

  private updateUserInLists(updated: User) {
    this.allUsers.update(list => list.map(u => u.id === updated.id ? { ...u, ...updated } : u));
    this.children.update(list => list.map(u => u.id === updated.id ? { ...u, ...updated } : u));
    this.parents.update(list => list.map(u => u.id === updated.id ? { ...u, ...updated } : u));

    if (this.selectedChild()?.id === updated.id) {
      this.selectedChild.set({ ...this.selectedChild()!, ...updated });
    }
    if (this.editingUser()?.id === updated.id) {
      this.editingUser.set({ ...this.editingUser()!, ...updated });
    }
  }

  // --- Quick Task Actions ---
  quickApprove(a: TaskAssignment) {
    this.assignmentService.updateStatus(a.id, AssignmentStatus.Approved).subscribe({
      next: () => {
        this.loadUsers();
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

    if (reason === null) return;

    this.assignmentService.updateStatus(a.id, AssignmentStatus.Rejected, reason || undefined).subscribe({
      next: () => {
        this.loadUsers();
        if (this.selectedChild()) this.selectChild(this.selectedChild()!);
        this.dialog.info(`Tugas '${a.taskTitle}' ditolak.`);
      },
      error: (err) => this.dialog.error('Gagal menolak: ' + (err.error?.message || 'Error'))
    });
  }

  quickReset(a: TaskAssignment) {
    this.assignmentService.updateStatus(a.id, AssignmentStatus.Pending).subscribe({
      next: () => {
        this.loadUsers();
        if (this.selectedChild()) this.selectChild(this.selectedChild()!);
        this.dialog.info(`Status tugas '${a.taskTitle}' direset ke Menunggu.`);
      },
      error: (err) => this.dialog.error('Gagal reset: ' + (err.error?.message || 'Error'))
    });
  }

  // --- Edit User Modal ---
  openEditModal(user: User, event?: Event) {
    if (event) event.stopPropagation();
    this.editingUser.set(user);
    this.editName.set(user.name);
    this.editPassword.set('');
    this.isEditing.set(true);
  }

  closeEditModal() {
    this.isEditing.set(false);
    this.editingUser.set(null);
    this.editName.set('');
    this.editPassword.set('');
  }

  saveUser() {
    const user = this.editingUser();
    const newName = this.editName().trim();
    if (!user || !newName) return;

    this.isSaving.set(true);
    const payload: { name: string; password?: string } = { name: newName };
    if (this.editPassword().trim()) {
      payload.password = this.editPassword().trim();
    }

    this.userService.updateUser(user.id, payload).subscribe({
      next: (updated) => {
        this.updateUserInLists(updated);
        this.isSaving.set(false);
        this.closeEditModal();
        this.dialog.success(`Data ${updated.name} berhasil disimpan!`);
      },
      error: (err) => {
        this.isSaving.set(false);
        this.dialog.error('Gagal memperbarui pengguna: ' + (err.error?.message || 'Error'));
      }
    });
  }

  // --- Create User Modal ---
  openCreateModal() {
    this.newName.set('');
    this.newEmail.set('');
    this.newPassword.set('');
    this.newRole.set(this.activeTab() === 'parents' ? UserRole.Admin : UserRole.Child);
    this.isCreating.set(true);
  }

  closeCreateModal() {
    this.isCreating.set(false);
  }

  createUser() {
    if (!this.newName().trim() || !this.newEmail().trim() || !this.newPassword().trim()) {
      this.dialog.error('Nama, Email, dan Password wajib diisi.');
      return;
    }

    this.isSaving.set(true);
    this.userService.createUser({
      name: this.newName().trim(),
      email: this.newEmail().trim(),
      password: this.newPassword().trim(),
      role: this.newRole()
    }).subscribe({
      next: (newUser) => {
        this.isSaving.set(false);
        this.closeCreateModal();
        this.loadUsers();
        this.dialog.success(`Pengguna '${newUser.name}' berhasil ditambahkan! 🎉`);
      },
      error: (err) => {
        this.isSaving.set(false);
        this.dialog.error('Gagal menambahkan pengguna: ' + (err.error?.message || 'Error'));
      }
    });
  }

  async confirmDeactivate(user: User, event?: Event) {
    if (event) event.stopPropagation();
    const confirmed = await this.dialog.confirm({
      title: 'Nonaktifkan Pengguna?',
      message: `Apakah Anda yakin ingin menonaktifkan akun "${user.name}"? Pengguna ini tidak akan bisa login lagi.`,
      confirmText: 'Nonaktifkan',
      cancelText: 'Batal',
      type: 'danger',
      icon: '⚠️'
    });

    if (!confirmed) return;

    this.userService.deleteUser(user.id).subscribe({
      next: () => {
        this.loadUsers();
        this.dialog.info(`Akun ${user.name} berhasil dinonaktifkan.`);
      },
      error: (err) => this.dialog.error('Gagal menonaktifkan: ' + (err.error?.message || 'Error'))
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
