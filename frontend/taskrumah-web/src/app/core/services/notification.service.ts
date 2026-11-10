import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Notification } from '../models/notification.model';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private apiUrl = `${environment.apiUrl}/notifications`;

  constructor(private http: HttpClient) {}

  getNotifications(unreadOnly = false) {
    return this.http.get<Notification[]>(`${this.apiUrl}?unreadOnly=${unreadOnly}`);
  }

  getUnreadCount() {
    return this.http.get<{ count: number }>(`${this.apiUrl}/unread-count`);
  }

  markRead(id: string) {
    return this.http.put(`${this.apiUrl}/${id}/read`, {});
  }

  markAllRead() {
    return this.http.put(`${this.apiUrl}/read-all`, {});
  }
}
