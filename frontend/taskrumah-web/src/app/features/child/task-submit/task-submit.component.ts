import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { TaskAssignment, AssignmentStatus } from '../../../core/models/task-assignment.model';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-task-submit',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './task-submit.component.html'
})
export class TaskSubmitComponent implements OnInit {
  assignment = signal<TaskAssignment | null>(null);
  note = '';
  selectedPhoto: File | null = null;
  photoPreview: string | null = null;
  loading = signal(true);
  submitting = signal(false);
  uploadsUrl = environment.uploadsUrl;
  AssignmentStatus = AssignmentStatus;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private assignmentService: TaskAssignmentService
  ) {}

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id')!;
    this.assignmentService.getAssignment(id).subscribe(a => {
      this.assignment.set(a);
      this.loading.set(false);
    });
  }

  canModify(): boolean {
    const a = this.assignment();
    if (!a) return false;
    const due = new Date(a.dueDate);
    const dueDateOnly = new Date(due.getFullYear(), due.getMonth(), due.getDate());
    const today = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    return dueDateOnly >= yesterday;
  }

  onPhotoSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files?.[0]) {
      this.selectedPhoto = input.files[0];
      const reader = new FileReader();
      reader.onload = (e) => this.photoPreview = e.target?.result as string;
      reader.readAsDataURL(this.selectedPhoto);
    }
  }

  submit() {
    if (!this.assignment()) return;
    this.submitting.set(true);
    this.assignmentService.submitTask(this.assignment()!.id, this.note, this.selectedPhoto || undefined)
      .subscribe({
        next: () => { this.router.navigate(['/child/tasks']); },
        error: () => this.submitting.set(false)
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
