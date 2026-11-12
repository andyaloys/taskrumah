import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../core/auth/auth.service';
import { UserService } from '../../../core/services/user.service';
import { User } from '../../../core/models/user.model';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { AssignmentStatus } from '../../../core/models/task-assignment.model';
import { DialogService } from '../../../core/services/dialog.service';
import { compressImage } from '../../../core/utils/image-compressor';

@Component({
  selector: 'app-child-profile',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './child-profile.component.html'
})
export class ChildProfileComponent implements OnInit {
  user = signal<User | null>(null);
  stats = signal({ approved: 0, rejected: 0, late: 0, total: 0 });

  isEditing = signal(false);
  isSaving = signal(false);
  isUploadingAvatar = signal(false);
  editName = signal('');

  constructor(
    private auth: AuthService,
    private userService: UserService,
    private assignmentService: TaskAssignmentService,
    private dialog: DialogService
  ) {}

  ngOnInit() {
    this.loadUser();
  }

  loadUser() {
    const userId = this.auth.currentUser()?.userId!;
    this.userService.getUser(userId).subscribe(u => this.user.set(u));
    this.assignmentService.getAssignments().subscribe(assignments => {
      this.stats.set({
        approved: assignments.filter(a => a.status === AssignmentStatus.Approved).length,
        rejected: assignments.filter(a => a.status === AssignmentStatus.Rejected).length,
        late: assignments.filter(a => a.status === AssignmentStatus.Late).length,
        total: assignments.length
      });
    });
  }

  triggerAvatarUpload(input: HTMLInputElement) {
    input.click();
  }

  async onAvatarFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const rawFile = input.files[0];
    const u = this.user();
    if (!u) return;

    this.isUploadingAvatar.set(true);

    try {
      const file = await compressImage(rawFile, 512, 0.85);
      this.userService.uploadAvatar(u.id, file).subscribe({
        next: (updated) => {
          this.user.set(updated);
          this.auth.updateCurrentUserProfile({ avatarUrl: updated.avatarUrl });
          this.isUploadingAvatar.set(false);
          input.value = '';
          this.dialog.success('Foto profil berhasil diperbarui! 📸');
        },
        error: (err) => {
          this.isUploadingAvatar.set(false);
          input.value = '';
          this.dialog.error('Gagal mengupload foto: ' + (err.error?.message || 'Error'));
        }
      });
    } catch {
      this.isUploadingAvatar.set(false);
      this.dialog.error('Gagal memproses gambar');
    }
  }

  openEditModal() {
    if (this.user()) {
      this.editName.set(this.user()!.name);
      this.isEditing.set(true);
    }
  }

  closeEditModal() {
    this.isEditing.set(false);
    this.editName.set('');
  }

  onNameInput(event: Event) {
    const target = event.target as HTMLInputElement;
    this.editName.set(target.value);
  }

  saveName() {
    const u = this.user();
    const newName = this.editName().trim();
    if (!u || !newName) return;

    this.isSaving.set(true);
    this.userService.updateUser(u.id, { name: newName }).subscribe({
      next: (updated) => {
        this.user.set(updated);
        this.auth.updateCurrentUserProfile({ name: updated.name });
        this.isSaving.set(false);
        this.closeEditModal();
        this.dialog.success(`Nama berhasil diubah menjadi '${updated.name}'`);
      },
      error: () => {
        this.isSaving.set(false);
        this.dialog.error('Gagal mengubah nama.');
      }
    });
  }

  getLevel(): { name: string; emoji: string } {
    const pts = this.user()?.totalPoints || 0;
    if (pts >= 500) return { name: 'Master Rumah', emoji: '🏆' };
    if (pts >= 200) return { name: 'Juara Kebersihan', emoji: '🌟' };
    if (pts >= 100) return { name: 'Pekerja Keras', emoji: '💪' };
    if (pts >= 50) return { name: 'Pemula Aktif', emoji: '🌱' };
    return { name: 'Baru Mulai', emoji: '👶' };
  }
}
