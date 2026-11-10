export enum NotificationType {
  TaskDue = 'TaskDue',
  TaskApproved = 'TaskApproved',
  TaskRejected = 'TaskRejected',
  RewardApproved = 'RewardApproved',
  NewTask = 'NewTask',
  TaskSubmitted = 'TaskSubmitted'
}

export interface Notification {
  id: string;
  title: string;
  message: string;
  type: NotificationType;
  isRead: boolean;
  relatedEntityId?: string;
  createdAt: Date;
}
