import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RewardService } from '../../../core/services/reward.service';
import { Reward, RewardRedemption, RedemptionStatus } from '../../../core/models/reward.model';
import { AuthService } from '../../../core/auth/auth.service';

@Component({
  selector: 'app-child-rewards',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './child-rewards.component.html'
})
export class ChildRewardsComponent implements OnInit {
  rewards = signal<Reward[]>([]);
  myRedemptions = signal<RewardRedemption[]>([]);
  loading = signal(true);
  redeeming = signal<string | null>(null);
  RedemptionStatus = RedemptionStatus;

  constructor(private rewardService: RewardService, private auth: AuthService) {}

  ngOnInit() {
    this.rewardService.getRewards().subscribe(r => { this.rewards.set(r); this.loading.set(false); });
    this.rewardService.getRedemptions().subscribe(r => this.myRedemptions.set(r));
  }

  redeem(reward: Reward) {
    const userPoints = this.auth.currentUser()?.totalPoints || 0;
    if (userPoints < reward.pointsRequired) {
      alert(`Poinmu belum cukup! Kamu punya ${userPoints} poin, butuh ${reward.pointsRequired} poin`);
      return;
    }
    if (!confirm(`Tukarkan "${reward.title}" seharga ${reward.pointsRequired} poin?`)) return;

    this.redeeming.set(reward.id);
    this.rewardService.redeemReward(reward.id).subscribe({
      next: () => {
        this.rewardService.getRedemptions().subscribe(r => this.myRedemptions.set(r));
        alert('✅ Permintaan hadiah dikirim! Tunggu persetujuan orang tua ya!');
        this.redeeming.set(null);
      },
      error: (err) => {
        alert(err.error?.message || 'Gagal menukarkan hadiah');
        this.redeeming.set(null);
      }
    });
  }

  getUserPoints(): number {
    return this.auth.currentUser()?.totalPoints || 0;
  }
}
