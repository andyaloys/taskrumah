import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { TaskAssignment, AssignmentStatus } from '../../../core/models/task-assignment.model';
import { AuthService } from '../../../core/auth/auth.service';

@Component({
  selector: 'app-my-tasks',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './my-tasks.component.html'
})
export class MyTasksComponent implements OnInit {
  assignments = signal<TaskAssignment[]>([]);
  tomorrowAssignments = signal<TaskAssignment[]>([]);
  loading = signal(true);
  activeView = signal<'today' | 'tomorrow' | 'all'>('today');
  filter = signal<AssignmentStatus | 'All'>('All');
  AssignmentStatus = AssignmentStatus;
  today = new Date();
  tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);

  constructor(private assignmentService: TaskAssignmentService, private auth: AuthService) {}

  ngOnInit() {
    this.loadTasks();
  }

  loadTasks() {
    this.loading.set(true);
    this.assignmentService.getAssignments().subscribe({
      next: (data) => { this.assignments.set(data); this.loading.set(false); },
      error: () => this.loading.set(false)
    });

    const tomorrowStr = this.formatDate(this.tomorrow);
    this.assignmentService.getSchedule(tomorrowStr).subscribe({
      next: (data) => this.tomorrowAssignments.set(data),
      error: () => {}
    });
  }

  formatDate(d: Date | string): string {
    const date = new Date(d);
    return date.toISOString().slice(0, 10);
  }

  filteredTasks() {
    if (this.activeView() === 'tomorrow') {
      return this.tomorrowAssignments();
    }
    if (this.activeView() === 'today') {
      const todayStr = this.formatDate(this.today);
      return this.assignments().filter(a => {
        if (!a.dueDate) return false;
        return this.formatDate(a.dueDate) === todayStr;
      });
    }
    const f = this.filter();
    if (f === 'All') return this.assignments();
    return this.assignments().filter(a => a.status === f);
  }

  canModify(dueDate: string | Date): boolean {
    if (!dueDate) return false;
    const due = new Date(dueDate);
    const dueDateOnly = new Date(due.getFullYear(), due.getMonth(), due.getDate());
    const today = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    return dueDateOnly >= yesterday;
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
