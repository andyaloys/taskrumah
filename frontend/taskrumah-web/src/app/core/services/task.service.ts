import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { ChoreTask, CreateTaskRequest, UpdateTaskRequest } from '../models/task.model';
import { TaskAssignment, TaskComment } from '../models/task-assignment.model';
import { AssignmentStatus } from '../models/task-assignment.model';

@Injectable({ providedIn: 'root' })
export class TaskService {
  private apiUrl = `${environment.apiUrl}/tasks`;

  constructor(private http: HttpClient) {}

  getTasks(activeOnly = true) {
    return this.http.get<ChoreTask[]>(`${this.apiUrl}?activeOnly=${activeOnly}`);
  }

  getExtraTasks() {
    return this.http.get<ChoreTask[]>(`${this.apiUrl}/extra`);
  }

  getTask(id: string) {
    return this.http.get<ChoreTask>(`${this.apiUrl}/${id}`);
  }

  createTask(task: CreateTaskRequest) {
    return this.http.post<ChoreTask>(this.apiUrl, task);
  }

  updateTask(id: string, task: UpdateTaskRequest) {
    return this.http.put<ChoreTask>(`${this.apiUrl}/${id}`, task);
  }

  deleteTask(id: string) {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  getTaskUsage(id: string) {
    return this.http.get<{
      taskId: string;
      title: string;
      totalAssignments: number;
      completedAssignments: number;
      pendingAssignments: number;
      hasHistory: boolean;
    }>(`${this.apiUrl}/${id}/usage`);
  }

  assignTask(id: string, req: { assignedToId?: string; dueDate?: string }) {
    return this.http.post<{ message: string }>(`${this.apiUrl}/${id}/assign`, req);
  }
}

@Injectable({ providedIn: 'root' })
export class TaskAssignmentService {
  private apiUrl = `${environment.apiUrl}/task-assignments`;

  constructor(private http: HttpClient) {}

  getAssignments(filters?: { userId?: string; status?: AssignmentStatus; date?: string }) {
    let params = new HttpParams();
    if (filters?.userId) params = params.set('userId', filters.userId);
    if (filters?.status) params = params.set('status', filters.status);
    if (filters?.date) params = params.set('date', filters.date);
    return this.http.get<TaskAssignment[]>(this.apiUrl, { params });
  }

  getSchedule(date: string, userId?: string) {
    let params = new HttpParams().set('date', date);
    if (userId) params = params.set('userId', userId);
    return this.http.get<TaskAssignment[]>(`${this.apiUrl}/schedule`, { params });
  }

  getAssignment(id: string) {
    return this.http.get<TaskAssignment>(`${this.apiUrl}/${id}`);
  }

  submitTask(id: string, note?: string, photo?: File) {
    const formData = new FormData();
    if (note) formData.append('submissionNote', note);
    if (photo) formData.append('photo', photo);
    return this.http.post<TaskAssignment>(`${this.apiUrl}/${id}/submit`, formData);
  }

  submitExtraTask(taskId: string, note?: string, photo?: File) {
    const formData = new FormData();
    formData.append('taskId', taskId);
    if (note) formData.append('submissionNote', note);
    if (photo) formData.append('photo', photo);
    return this.http.post<TaskAssignment>(`${this.apiUrl}/submit-extra`, formData);
  }

  approveTask(id: string) {
    return this.http.post<TaskAssignment>(`${this.apiUrl}/${id}/approve`, {});
  }

  rejectTask(id: string, reason?: string) {
    return this.http.post<TaskAssignment>(`${this.apiUrl}/${id}/reject`, { rejectionReason: reason || 'Ditolak oleh orang tua' });
  }

  updateStatus(id: string, status: AssignmentStatus, reason?: string) {
    return this.http.put<TaskAssignment>(`${this.apiUrl}/${id}/status`, { status, reason });
  }

  getComments(id: string) {
    return this.http.get<TaskComment[]>(`${this.apiUrl}/${id}/comments`);
  }

  addComment(id: string, comment: string) {
    return this.http.post<TaskComment>(`${this.apiUrl}/${id}/comments`, { comment });
  }
}
