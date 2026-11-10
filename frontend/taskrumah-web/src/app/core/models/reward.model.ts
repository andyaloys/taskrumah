export enum RedemptionStatus {
  Pending = 'Pending',
  Approved = 'Approved',
  Rejected = 'Rejected'
}

export interface Reward {
  id: string;
  title: string;
  description?: string;
  pointsRequired: number;
  iconEmoji: string;
  isActive: boolean;
  createdAt: Date;
}

export interface RewardRedemption {
  id: string;
  rewardId: string;
  rewardTitle: string;
  rewardIconEmoji: string;
  pointsRequired: number;
  userId: string;
  userName: string;
  status: RedemptionStatus;
  requestedAt: Date;
  processedAt?: Date;
  processedByName?: string;
  notes?: string;
}
