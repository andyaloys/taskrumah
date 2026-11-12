import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { User } from '../models/user.model';

@Injectable({ providedIn: 'root' })
export class UserService {
  private apiUrl = `${environment.apiUrl}/users`;

  constructor(private http: HttpClient) {}

  getUsers() {
    return this.http.get<User[]>(this.apiUrl);
  }

  getChildren() {
    return this.http.get<User[]>(`${this.apiUrl}/children`);
  }

  getUser(id: string) {
    return this.http.get<User>(`${this.apiUrl}/${id}`);
  }

  createUser(data: { name: string; email: string; password: string; role?: string }) {
    return this.http.post<User>(this.apiUrl, data);
  }

  updateUser(id: string, data: { name?: string; avatarUrl?: string; password?: string }) {
    return this.http.put<User>(`${this.apiUrl}/${id}`, data);
  }

  uploadAvatar(id: string, file: File) {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<User>(`${this.apiUrl}/${id}/avatar`, formData);
  }

  deleteUser(id: string) {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/${id}`);
  }
}
