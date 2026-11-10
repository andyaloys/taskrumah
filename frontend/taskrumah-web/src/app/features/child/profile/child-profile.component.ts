import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../core/auth/auth.service';
import { UserService } from '../../../core/services/user.service';
import { User } from '../../../core/models/user.model';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { AssignmentStatus } from '../../../core/models/task-assignment.model';

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
  editName = signal('');

  constructor(
    private auth: AuthService,
    private userService: UserService,
    private assignmentService: TaskAssignmentService
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
        // update stored user in auth service so navbar reflects it
        const current = this.auth.currentUser();
        if (current) {
          const updatedAuth = { ...current, name: updated.name };
          localStorage.setItem('taskrumah_user', JSON.stringify(updatedAuth));
          this.auth.currentUser.set(updatedAuth);
        }
        this.isSaving.set(false);
        this.closeEditModal();
      },
      error: () => {
        this.isSaving.set(false);
        alert('Gagal mengubah nama.');
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
