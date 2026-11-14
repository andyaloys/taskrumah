import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Observable } from 'rxjs';

export enum PrayerStatus {
  None = 'None',
  Solo = 'Solo',
  Mosque = 'Mosque'
}

export interface WorshipSetting {
  id: string;
  soloPoints: number;
  mosquePoints: number;
  quranPoints: number;
  reminderMinutesBeforeEnd?: number;
  quranReminderTime?: string;
  updatedAt: string;
}

export interface DailyWorship {
  id: string;
  userId: string;
  date: string;
  subuh: PrayerStatus;
  dzuhur: PrayerStatus;
  ashar: PrayerStatus;
  maghrib: PrayerStatus;
  isya: PrayerStatus;
  quranDone: boolean;
  quranNote?: string;
  totalPointsEarned: number;
  createdAt: string;
  updatedAt: string;
}

export interface AdminChildWorshipSummary {
  userId: string;
  userName: string;
  avatarUrl?: string;
  totalPoints: number;
  date: string;
  subuh: PrayerStatus;
  dzuhur: PrayerStatus;
  ashar: PrayerStatus;
  maghrib: PrayerStatus;
  isya: PrayerStatus;
  quranDone: boolean;
  quranNote?: string;
  pointsEarnedToday: number;
}

@Injectable({
  providedIn: 'root'
})
export class WorshipService {
  private apiUrl = `${environment.apiUrl}/worship`;

  constructor(private http: HttpClient) {}

  getSetting(): Observable<WorshipSetting> {
    return this.http.get<WorshipSetting>(`${this.apiUrl}/setting`);
  }

  updateSetting(req: { soloPoints: number; mosquePoints: number; quranPoints: number }): Observable<WorshipSetting> {
    return this.http.put<WorshipSetting>(`${this.apiUrl}/setting`, req);
  }

  getMyWorship(date?: string): Observable<DailyWorship> {
    const url = date ? `${this.apiUrl}/my?date=${date}` : `${this.apiUrl}/my`;
    return this.http.get<DailyWorship>(url);
  }

  saveWorship(req: {
    date?: string;
    subuh: PrayerStatus;
    dzuhur: PrayerStatus;
    ashar: PrayerStatus;
    maghrib: PrayerStatus;
    isya: PrayerStatus;
    quranDone: boolean;
    quranNote?: string;
  }): Observable<{ record: DailyWorship; userTotalPoints: number; message: string }> {
    return this.http.post<{ record: DailyWorship; userTotalPoints: number; message: string }>(
      `${this.apiUrl}/save`,
      req
    );
  }

  getAdminSummary(date?: string): Observable<AdminChildWorshipSummary[]> {
    const url = date ? `${this.apiUrl}/admin/summary?date=${date}` : `${this.apiUrl}/admin/summary`;
    return this.http.get<AdminChildWorshipSummary[]>(url);
  }
}
