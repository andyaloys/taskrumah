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

  getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }
}
