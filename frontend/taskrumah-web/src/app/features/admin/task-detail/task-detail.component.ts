import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { TaskAssignment, TaskComment, AssignmentStatus } from '../../../core/models/task-assignment.model';
import { AuthService } from '../../../core/auth/auth.service';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-task-detail',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './task-detail.component.html'
})
export class TaskDetailComponent implements OnInit {
  assignment = signal<TaskAssignment | null>(null);
  comments = signal<TaskComment[]>([]);
  loading = signal(true);
  newComment = '';
  AssignmentStatus = AssignmentStatus;
  uploadsUrl = environment.uploadsUrl;

  constructor(
    private route: ActivatedRoute,
    private assignmentService: TaskAssignmentService,
    public auth: AuthService
  ) {}

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id')!;
    this.loadData(id);
  }

  loadData(id: string) {
    this.loading.set(true);
    this.assignmentService.getAssignment(id).subscribe(a => {
      this.assignment.set(a);
      this.loading.set(false);
    });
    this.assignmentService.getComments(id).subscribe(c => this.comments.set(c));
  }

  approve() {
    const id = this.assignment()!.id;
    this.assignmentService.approveTask(id).subscribe(() => this.loadData(id));
  }

  reject() {
    const reason = prompt('Alasan penolakan:');
    if (reason) {
      const id = this.assignment()!.id;
      this.assignmentService.rejectTask(id, reason).subscribe(() => this.loadData(id));
    }
  }

  sendComment() {
    if (!this.newComment.trim()) return;
    const id = this.assignment()!.id;
    this.assignmentService.addComment(id, this.newComment).subscribe(c => {
      this.comments.update(list => [...list, c]);
      this.newComment = '';
    });
  }
}
