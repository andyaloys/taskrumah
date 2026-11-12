import { Component, OnInit, signal } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { AuthService } from '../../../core/auth/auth.service';
import { UserRole } from '../../../core/models/user.model';
import { environment } from '../../../../environments/environment';

export interface QuickUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatarUrl?: string;
}

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  form: FormGroup;
  loading = signal(false);
  error = signal('');
  showPassword = signal(false);

  quickPasswords: Record<string, string> = {
    'ayah@taskrumah.com': 'Ayah@123',
    'ibu@taskrumah.com': 'Ibu@123',
    'anak1@taskrumah.com': 'Anak1@123',
    'anak2@taskrumah.com': 'Anak2@123',
  };

  quickUsers = signal<QuickUser[]>([
    { id: '1', name: 'Papah', email: 'ayah@taskrumah.com', role: UserRole.Admin },
    { id: '2', name: 'Mamah', email: 'ibu@taskrumah.com', role: UserRole.Admin },
    { id: '3', name: 'Kakak', email: 'anak1@taskrumah.com', role: UserRole.Child },
    { id: '4', name: 'Dedee', email: 'anak2@taskrumah.com', role: UserRole.Child }
  ]);

  constructor(
    private fb: FormBuilder,
    private auth: AuthService,
    private router: Router,
    private http: HttpClient
  ) {
    this.form = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required]
    });
  }

  ngOnInit() {
    this.loadQuickUsers();
  }

  loadQuickUsers() {
    this.http.get<QuickUser[]>(`${environment.apiUrl}/auth/quick-users`).subscribe({
      next: (users) => {
        if (users && users.length > 0) {
          this.quickUsers.set(users);
        }
      },
      error: () => {}
    });
  }

  togglePassword() {
    this.showPassword.update(v => !v);
  }

  onSubmit() {
    if (this.form.invalid) return;
    this.loading.set(true);
    this.error.set('');

    this.auth.login(this.form.value).subscribe({
      next: (res) => {
        if (res.role === UserRole.Admin) {
          this.router.navigate(['/admin/dashboard']);
        } else {
          this.router.navigate(['/child/dashboard']);
        }
      },
      error: (err) => {
        this.error.set(err.error?.message || 'Login gagal. Periksa email dan password kamu.');
        this.loading.set(false);
      }
    });
  }

  quickLogin(email: string, password: string) {
    this.form.patchValue({ email, password });
    this.onSubmit();
  }

  getRoleBadge(role: UserRole): { label: string; textClass: string; bgClass: string; borderClass: string } {
    if (role === UserRole.Admin) {
      return {
        label: 'Admin',
        textClass: 'text-indigo-400',
        bgClass: 'bg-indigo-500/10',
        borderClass: 'border-indigo-500/30 hover:border-indigo-500/50'
      };
    }
    return {
      label: 'Anak',
      textClass: 'text-amber-400',
      bgClass: 'bg-amber-500/10',
      borderClass: 'border-amber-500/30 hover:border-amber-500/50'
    };
  }

  getDefaultEmoji(name: string, role: UserRole): string {
    const lower = name.toLowerCase();
    if (lower.includes('papah') || lower.includes('ayah')) return '👨';
    if (lower.includes('mamah') || lower.includes('ibu') || lower.includes('bunda')) return '👩';
    if (lower.includes('kakak')) return '🧑';
    if (lower.includes('dedee') || lower.includes('adik')) return '👧';
    return role === UserRole.Admin ? '👨‍👩‍👧' : '🧒';
  }
}
