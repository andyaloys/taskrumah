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
      [AssignmentStatus.Pending]: 'bg-yellow-100 text-yellow-800',
      [AssignmentStatus.Submitted]: 'bg-blue-100 text-blue-800',
      [AssignmentStatus.Approved]: 'bg-green-100 text-green-800',
      [AssignmentStatus.Rejected]: 'bg-red-100 text-red-800',
      [AssignmentStatus.Late]: 'bg-gray-100 text-gray-600',
    };
    return classes[status] || '';
  }
}
