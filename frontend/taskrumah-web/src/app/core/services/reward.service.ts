import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Reward, RewardRedemption, RedemptionStatus } from '../models/reward.model';

@Injectable({ providedIn: 'root' })
export class RewardService {
  private apiUrl = `${environment.apiUrl}/rewards`;

  constructor(private http: HttpClient) {}

  getRewards() {
    return this.http.get<Reward[]>(this.apiUrl);
  }

  createReward(reward: { title: string; description?: string; pointsRequired: number; iconEmoji: string }) {
    return this.http.post<Reward>(this.apiUrl, reward);
  }

  updateReward(id: string, reward: Partial<Reward>) {
    return this.http.put<Reward>(`${this.apiUrl}/${id}`, reward);
  }

  deleteReward(id: string) {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  redeemReward(id: string) {
    return this.http.post(`${this.apiUrl}/${id}/redeem`, {});
  }

  getRedemptions(filters?: { userId?: string; status?: RedemptionStatus }) {
    let params = new HttpParams();
    if (filters?.userId) params = params.set('userId', filters.userId);
    if (filters?.status) params = params.set('status', filters.status);
    return this.http.get<RewardRedemption[]>(`${this.apiUrl}/redemptions`, { params });
  }

  processRedemption(id: string, status: RedemptionStatus, notes?: string) {
    return this.http.put(`${this.apiUrl}/redemptions/${id}`, { status, notes });
  }
}
