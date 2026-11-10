import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { DashboardService, ChildDashboard } from '../../../core/services/dashboard.service';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { AuthService } from '../../../core/auth/auth.service';
import { AssignmentStatus, TaskAssignment } from '../../../core/models/task-assignment.model';

export interface WeekDayItem {
  date: Date;
  dateStr: string;
  dayName: string;
  dayNumber: number;
  isToday: boolean;
  isYesterday: boolean;
  isTomorrow: boolean;
  isPast: boolean;
  isFuture: boolean;
}

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
  AssignmentStatus = AssignmentStatus;

  today = new Date();
  yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
  tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);

  selectedDateStr = signal<string>('');
  selectedDateTasks = signal<TaskAssignment[]>([]);
  loadingDayTasks = signal<boolean>(false);

  constructor(
    private dashboardService: DashboardService,
    private assignmentService: TaskAssignmentService,
    private auth: AuthService
  ) {
    this.selectedDateStr.set(this.formatLocalDate(this.today));
  }

  ngOnInit() {
    this.loadDashboard();
  }

  formatLocalDate(d: Date | string): string {
    const date = new Date(d);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  loadDashboard() {
    const userId = this.auth.currentUser()?.userId!;
    if (!userId) return;
    this.loading.set(true);
    this.dashboardService.getChildDashboard(userId, this.currentWeekOffset()).subscribe({
      next: (data) => {
        this.dashboard.set(data);
        this.loading.set(false);

        // Determine active selected day
        let targetDateStr = this.selectedDateStr();
        const weekDays = this.getWeekDays();
        const dateInWeek = weekDays.some(d => d.dateStr === targetDateStr);

        if (!dateInWeek) {
          // If viewing current week, select today; otherwise select Monday of that week
          if (this.currentWeekOffset() === 0) {
            targetDateStr = this.formatLocalDate(this.today);
          } else if (weekDays.length > 0) {
            targetDateStr = weekDays[0].dateStr;
          }
          this.selectedDateStr.set(targetDateStr);
        }

        this.loadDayTasks(targetDateStr);
      },
      error: () => this.loading.set(false)
    });
  }

  getWeekDays(): WeekDayItem[] {
    const dash = this.dashboard();
    if (!dash?.weekStart) return [];

    const [y, m, d] = dash.weekStart.slice(0, 10).split('-').map(Number);
    const startDate = new Date(y, m - 1, d);

    const days: WeekDayItem[] = [];
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    const now = new Date();
    const todayTime = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const yestTime = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1).getTime();
    const tomTime = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1).getTime();

    for (let i = 0; i < 7; i++) {
      const cur = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + i);
      const curTime = cur.getTime();
      const dateStr = this.formatLocalDate(cur);

      days.push({
        date: cur,
        dateStr: dateStr,
        dayName: dayNames[cur.getDay()],
        dayNumber: cur.getDate(),
        isToday: curTime === todayTime,
        isYesterday: curTime === yestTime,
        isTomorrow: curTime === tomTime,
        isPast: curTime < todayTime,
        isFuture: curTime > todayTime
      });
    }
    return days;
  }

  getSelectedDay(): WeekDayItem | undefined {
    return this.getWeekDays().find(d => d.dateStr === this.selectedDateStr());
  }

  selectDay(day: WeekDayItem) {
    this.selectedDateStr.set(day.dateStr);
    this.loadDayTasks(day.dateStr);
  }

  loadDayTasks(dateStr: string) {
    this.loadingDayTasks.set(true);
    this.assignmentService.getSchedule(dateStr).subscribe({
      next: (tasks) => {
        this.selectedDateTasks.set(tasks);
        this.loadingDayTasks.set(false);
      },
      error: () => this.loadingDayTasks.set(false)
    });
  }

  changeWeek(delta: number) {
    this.currentWeekOffset.update(w => w + delta);
    this.loadDashboard();
  }

  setWeek(offset: number) {
    this.currentWeekOffset.set(offset);
    this.selectedDateStr.set(this.formatLocalDate(this.today));
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
