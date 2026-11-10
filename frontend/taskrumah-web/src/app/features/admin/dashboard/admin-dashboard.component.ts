import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { DashboardService, AdminDashboard } from '../../../core/services/dashboard.service';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { AssignmentStatus } from '../../../core/models/task-assignment.model';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './admin-dashboard.component.html'
})
export class AdminDashboardComponent implements OnInit {
  dashboard = signal<AdminDashboard | null>(null);
  loading = signal(true);
  currentWeekOffset = signal(0);
  today = new Date();
  tomorrow = new Date(Date.now() + 86400000);
  dayAfter = new Date(Date.now() + 2 * 86400000);
  selectedDate = signal<string>('');
  dateViewMode = signal<'today' | 'tomorrow' | 'dayAfter' | 'custom'>('today');

  constructor(
    private dashboardService: DashboardService,
    private assignmentService: TaskAssignmentService
  ) {}

  ngOnInit() {
    this.loadDashboard();
  }

  formatDate(d: Date | string): string {
    const date = new Date(d);
    return date.toISOString().slice(0, 10);
  }

  selectDateMode(mode: 'today' | 'tomorrow' | 'dayAfter' | 'custom', customDate?: string) {
    this.dateViewMode.set(mode);
    if (mode === 'today') {
      this.selectedDate.set('');
      this.currentWeekOffset.set(0);
    } else if (mode === 'tomorrow') {
      this.selectedDate.set(this.formatDate(this.tomorrow));
      this.currentWeekOffset.set(0);
    } else if (mode === 'dayAfter') {
      this.selectedDate.set(this.formatDate(this.dayAfter));
      this.currentWeekOffset.set(0);
    } else if (mode === 'custom' && customDate) {
      this.selectedDate.set(customDate);
      this.currentWeekOffset.set(0);
    }
    this.loadDashboard();
  }

  onCustomDateChange(event: Event) {
    const val = (event.target as HTMLInputElement).value;
    if (val) {
      this.selectDateMode('custom', val);
    }
  }

  isFutureDate(): boolean {
    if (!this.selectedDate()) return false;
    const today = new Date();
    const todayDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const sel = new Date(this.selectedDate());
    return sel > todayDate;
  }

  loadDashboard() {
    this.loading.set(true);
    this.dashboardService.getAdminDashboard(this.currentWeekOffset(), this.selectedDate() || undefined).subscribe({
      next: (data) => { this.dashboard.set(data); this.loading.set(false); },
      error: () => this.loading.set(false)
    });
  }

  changeWeek(delta: number) {
    this.selectedDate.set('');
    this.dateViewMode.set('today');
    this.currentWeekOffset.update(w => w + delta);
    this.loadDashboard();
  }

  setWeek(offset: number) {
    this.selectedDate.set('');
    this.dateViewMode.set('today');
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

  approve(assignmentId: string) {
    this.assignmentService.approveTask(assignmentId).subscribe(() => this.loadDashboard());
  }

  reject(assignmentId: string) {
    const reason = prompt('Alasan penolakan:');
    if (reason) {
      this.assignmentService.rejectTask(assignmentId, reason).subscribe(() => this.loadDashboard());
    }
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

  getProgressPercent(completed: number, total: number): number {
    if (total === 0) return 0;
    return Math.round((completed / total) * 100);
  }

  AssignmentStatus = AssignmentStatus;
}
