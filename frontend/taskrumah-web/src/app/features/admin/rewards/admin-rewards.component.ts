import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { RewardService } from '../../../core/services/reward.service';
import { Reward, RewardRedemption, RedemptionStatus } from '../../../core/models/reward.model';
import { DialogService } from '../../../core/services/dialog.service';

@Component({
  selector: 'app-admin-rewards',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './admin-rewards.component.html'
})
export class AdminRewardsComponent implements OnInit {
  rewards = signal<Reward[]>([]);
  redemptions = signal<RewardRedemption[]>([]);
  loading = signal(true);
  showForm = signal(false);
  editingReward = signal<Reward | null>(null);
  form: FormGroup;
  saving = signal(false);
  RedemptionStatus = RedemptionStatus;

  emojiOptions = ['🍦', '🎮', '🎬', '🏖️', '🍕', '🧁', '📱', '🚲', '🎪', '🎡'];

  constructor(
    private rewardService: RewardService,
    private fb: FormBuilder,
    private dialog: DialogService
  ) {
    this.form = this.fb.group({
      title: ['', Validators.required],
      description: [''],
      pointsRequired: [30, [Validators.required, Validators.min(1)]],
      iconEmoji: ['🎁', Validators.required]
    });
  }

  ngOnInit() {
    this.loadData();
  }

  loadData() {
    this.loading.set(true);
    this.rewardService.getRewards().subscribe(r => { this.rewards.set(r); this.loading.set(false); });
    this.rewardService.getRedemptions().subscribe(r => this.redemptions.set(r));
  }

  openCreate() {
    this.editingReward.set(null);
    this.form.reset({ pointsRequired: 30, iconEmoji: '🎁' });
    this.showForm.set(true);
  }

  openEdit(reward: Reward) {
    this.editingReward.set(reward);
    this.form.patchValue(reward);
    this.showForm.set(true);
  }

  save() {
    if (this.form.invalid) return;
    this.saving.set(true);
    const data = this.form.value;
    const request = this.editingReward()
      ? this.rewardService.updateReward(this.editingReward()!.id, data)
      : this.rewardService.createReward(data);

    request.subscribe({
      next: () => {
        this.showForm.set(false);
        this.loadData();
        this.saving.set(false);
        this.dialog.success(this.editingReward() ? 'Hadiah berhasil diperbarui!' : 'Hadiah baru berhasil dibuat!');
      },
      error: (err) => {
        this.saving.set(false);
        this.dialog.error(err.error?.message || 'Gagal menyimpan hadiah');
      }
    });
  }

  async processRedemption(id: string, status: RedemptionStatus) {
    let notes: string | undefined = undefined;
    if (status === RedemptionStatus.Rejected) {
      const input = await this.dialog.prompt({
        title: 'Tolak Permintaan Hadiah?',
        message: 'Masukkan alasan/catatan penolakan hadiah (opsional):',
        placeholder: 'Contoh: Poin belum mencukupi / tunda dulu',
        confirmText: 'Tolak Hadiah',
        cancelText: 'Batal',
        type: 'danger',
        icon: '❌'
      });
      if (input === null) return; // User cancelled
      notes = input || undefined;
    }

    this.rewardService.processRedemption(id, status, notes).subscribe({
      next: () => {
        this.loadData();
        this.dialog.success(status === RedemptionStatus.Approved ? 'Klaim hadiah disetujui & poin dipotong.' : 'Klaim hadiah ditolak.');
      },
      error: (err) => this.dialog.error(err.error?.message || 'Gagal memproses hadiah')
    });
  }

  async deleteReward(reward: Reward) {
    const confirmed = await this.dialog.confirm({
      title: 'Hapus Hadiah?',
      message: `Yakin ingin menghapus hadiah "${reward.title}"?`,
      confirmText: 'Ya, Hapus',
      cancelText: 'Batal',
      icon: '🗑️',
      type: 'danger'
    });

    if (!confirmed) return;

    this.rewardService.deleteReward(reward.id).subscribe({
      next: () => {
        this.loadData();
        this.dialog.success(`Hadiah "${reward.title}" berhasil dihapus.`);
      },
      error: (err) => this.dialog.error('Gagal menghapus hadiah: ' + (err.error?.message || 'Error'))
    });
  }

  selectEmoji(emoji: string) {
    this.form.patchValue({ iconEmoji: emoji });
  }

  getPendingRedemptions() {
    return this.redemptions().filter(r => r.status === RedemptionStatus.Pending);
  }
}
