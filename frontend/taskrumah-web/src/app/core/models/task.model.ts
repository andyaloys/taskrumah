export enum TaskType {
  Daily = 'Daily',
  SpecificDays = 'SpecificDays',
  OneTime = 'OneTime'
}

export interface ChoreTask {
  id: string;
  title: string;
  description?: string;
  taskType: TaskType;
  daysOfWeek?: string;
  assignedToId?: string;
  assignedToName?: string;
  createdById: string;
  createdByName: string;
  points: number;
  iconEmoji: string;
  isActive: boolean;
  createdAt: Date;
}

export interface CreateTaskRequest {
  title: string;
  description?: string;
  taskType: TaskType;
  daysOfWeek?: string;
  assignedToId?: string;
  points: number;
  iconEmoji: string;
  dueDate?: string;
}

export interface UpdateTaskRequest {
  title?: string;
  description?: string;
  taskType?: TaskType;
  daysOfWeek?: string;
  assignedToId?: string;
  points?: number;
  iconEmoji?: string;
  isActive?: boolean;
}

export interface AssignTaskRequest {
  assignedToId?: string;
  dueDate?: string;
}
