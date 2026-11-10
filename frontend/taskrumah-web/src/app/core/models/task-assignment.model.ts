export enum AssignmentStatus {
  Pending = 'Pending',
  Submitted = 'Submitted',
  Approved = 'Approved',
  Rejected = 'Rejected',
  Late = 'Late'
}

export interface TaskAssignment {
  id: string;
  taskId: string;
  taskTitle: string;
  taskIconEmoji: string;
  taskPoints: number;
  assignedToId: string;
  assignedToName: string;
  assignedToAvatarUrl?: string;
  dueDate: Date;
  status: AssignmentStatus;
  proofPhotoUrl?: string;
  submissionNote?: string;
  completedAt?: Date;
  reviewedAt?: Date;
  reviewedByName?: string;
  rejectionReason?: string;
  createdAt: Date;
  commentCount: number;
}

export interface TaskComment {
  id: string;
  taskAssignmentId: string;
  userId: string;
  userName: string;
  userAvatarUrl?: string;
  userRole: string;
  comment: string;
  createdAt: Date;
}
