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

  updateUser(id: string, data: { name?: string; avatarUrl?: string }) {
    return this.http.put<User>(`${this.apiUrl}/${id}`, data);
  }
}
