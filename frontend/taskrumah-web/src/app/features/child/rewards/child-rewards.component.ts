import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RewardService } from '../../../core/services/reward.service';
import { Reward, RewardRedemption, RedemptionStatus } from '../../../core/models/reward.model';
import { AuthService } from '../../../core/auth/auth.service';
import { DialogService } from '../../../core/services/dialog.service';

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

  constructor(
    private rewardService: RewardService,
    private auth: AuthService,
    private dialog: DialogService
  ) {}

  ngOnInit() {
    this.rewardService.getRewards().subscribe(r => { this.rewards.set(r); this.loading.set(false); });
    this.rewardService.getRedemptions().subscribe(r => this.myRedemptions.set(r));
  }

  async redeem(reward: Reward) {
    const userPoints = this.auth.currentUser()?.totalPoints || 0;
    if (userPoints < reward.pointsRequired) {
      this.dialog.warning(`Poinmu belum cukup! Kamu punya ${userPoints} poin, butuh ${reward.pointsRequired} poin.`);
      return;
    }

    const confirmed = await this.dialog.confirm({
      title: 'Tukarkan Hadiah?',
      message: `Tukarkan "${reward.title}" seharga ${reward.pointsRequired} poin?\nPermintaan akan dikirimkan ke orang tua untuk disetujui.`,
      confirmText: 'Ya, Tukarkan',
      cancelText: 'Batal',
      icon: reward.iconEmoji || '🎁',
      type: 'primary'
    });

    if (!confirmed) return;

    this.redeeming.set(reward.id);
    this.rewardService.redeemReward(reward.id).subscribe({
      next: () => {
        this.rewardService.getRedemptions().subscribe(r => this.myRedemptions.set(r));
        this.dialog.success(`Permintaan hadiah "${reward.title}" berhasil dikirim! Tunggu persetujuan orang tua ya.`);
        this.redeeming.set(null);
      },
      error: (err) => {
        this.dialog.error(err.error?.message || 'Gagal menukarkan hadiah');
        this.redeeming.set(null);
      }
    });
  }

  getUserPoints(): number {
    return this.auth.currentUser()?.totalPoints || 0;
  }

  getRedemptionStatusLabel(status: RedemptionStatus): string {
    const labels: Record<RedemptionStatus, string> = {
      [RedemptionStatus.Pending]: 'Menunggu Persetujuan',
      [RedemptionStatus.Approved]: 'Disetujui',
      [RedemptionStatus.Rejected]: 'Ditolak',
    };
    return labels[status] || status;
  }

  getRedemptionStatusClass(status: RedemptionStatus): string {
    const classes: Record<RedemptionStatus, string> = {
      [RedemptionStatus.Pending]: 'bg-amber-50 text-amber-700 border border-amber-200/80',
      [RedemptionStatus.Approved]: 'bg-emerald-50 text-emerald-700 border border-emerald-200/80',
      [RedemptionStatus.Rejected]: 'bg-rose-50 text-rose-700 border border-rose-200/80',
    };
    return classes[status] || 'bg-slate-100 text-slate-700 border border-slate-200/80';
  }
}
