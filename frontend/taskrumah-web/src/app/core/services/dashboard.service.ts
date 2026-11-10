import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { TaskAssignment } from '../models/task-assignment.model';
import { Notification } from '../models/notification.model';
import { User } from '../models/user.model';

export interface ChildProgress {
  userId: string;
  name: string;
  avatarUrl?: string;
  totalPoints: number;
  currentStreak: number;
  tasksToday: number;
  tasksCompleted: number;
  tasksPending: number;
  todayTasks: TaskAssignment[];
  weeklyPoints: number;
}

export interface AdminDashboard {
  children: ChildProgress[];
  pendingReviews: TaskAssignment[];
  totalTasksToday: number;
  totalApprovedToday: number;
  weekStart: string;
  weekEnd: string;
  weekOffset: number;
  targetDate: string;
}

export interface ChildDashboard {
  userId: string;
  name: string;
  avatarUrl?: string;
  totalPoints: number;
  currentStreak: number;
  longestStreak: number;
  tasksToday: number;
  tasksCompleted: number;
  todayTasks: TaskAssignment[];
  tomorrowTasks: TaskAssignment[];
  recentNotifications: Notification[];
  weeklyPoints: number;
  weekStart: string;
  weekEnd: string;
  weekOffset: number;
  targetDate: string;
}

@Injectable({ providedIn: 'root' })
export class DashboardService {
  private apiUrl = `${environment.apiUrl}/dashboard`;

  constructor(private http: HttpClient) {}

  getAdminDashboard(weekOffset: number = 0, date?: string) {
    let url = `${this.apiUrl}/admin?weekOffset=${weekOffset}`;
    if (date) url += `&date=${encodeURIComponent(date)}`;
    return this.http.get<AdminDashboard>(url);
  }

  getChildDashboard(userId: string, weekOffset: number = 0, date?: string) {
    let url = `${this.apiUrl}/child/${userId}?weekOffset=${weekOffset}`;
    if (date) url += `&date=${encodeURIComponent(date)}`;
    return this.http.get<ChildDashboard>(url);
  }
}
