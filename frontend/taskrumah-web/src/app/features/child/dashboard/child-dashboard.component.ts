import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { DashboardService, ChildDashboard } from '../../../core/services/dashboard.service';
import { AuthService } from '../../../core/auth/auth.service';
import { AssignmentStatus } from '../../../core/models/task-assignment.model';

@Component({
  selector: 'app-child-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './child-dashboard.component.html'
})
export class ChildDashboardComponent implements OnInit {
  dashboard = signal<ChildDashboard | null>(null);
  loading = signal(true);
  currentWeekOffset = signal(0);
  activeDayTab = signal<'today' | 'tomorrow'>('today');
  AssignmentStatus = AssignmentStatus;
  today = new Date();
  tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);

  constructor(private dashboardService: DashboardService, private auth: AuthService) {}

  ngOnInit() {
    this.loadDashboard();
  }

  loadDashboard() {
    const userId = this.auth.currentUser()?.userId!;
    if (!userId) return;
    this.loading.set(true);
    this.dashboardService.getChildDashboard(userId, this.currentWeekOffset()).subscribe({
      next: (data) => { this.dashboard.set(data); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }

  changeWeek(delta: number) {
    this.currentWeekOffset.update(w => w + delta);
    this.loadDashboard();
  }

  setWeek(offset: number) {
    this.currentWeekOffset.set(offset);
    this.loadDashboard();
  }

  abs(val: number): number {
    return Math.abs(val);
  }

  canModify(dueDate: string | Date): boolean {
    if (!dueDate) return false;
    const due = new Date(dueDate);
    const dueDateOnly = new Date(due.getFullYear(), due.getMonth(), due.getDate());
    const today = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    return dueDateOnly >= yesterday;
  }

  getProgressPercent(): number {
    const d = this.dashboard();
    if (!d || d.tasksToday === 0) return 0;
    return Math.round((d.tasksCompleted / d.tasksToday) * 100);
  }

  getStatusClass(status: AssignmentStatus): string {
    const classes: Record<AssignmentStatus, string> = {
      [AssignmentStatus.Pending]: 'bg-yellow-100 text-yellow-800 border-yellow-300',
      [AssignmentStatus.Submitted]: 'bg-blue-100 text-blue-800 border-blue-300',
      [AssignmentStatus.Approved]: 'bg-green-100 text-green-800 border-green-300',
      [AssignmentStatus.Rejected]: 'bg-red-100 text-red-800 border-red-300',
      [AssignmentStatus.Late]: 'bg-gray-100 text-gray-600 border-gray-300',
    };
    return classes[status] || '';
  }

  getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }
}
