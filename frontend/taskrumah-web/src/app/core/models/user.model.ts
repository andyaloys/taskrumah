export enum UserRole {
  Admin = 'Admin',
  Child = 'Child'
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatarUrl?: string;
  totalPoints: number;
  currentStreak: number;
  longestStreak: number;
  isActive: boolean;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  userId: string;
  name: string;
  email: string;
  role: UserRole;
  avatarUrl?: string;
  totalPoints: number;
  currentStreak: number;
}
