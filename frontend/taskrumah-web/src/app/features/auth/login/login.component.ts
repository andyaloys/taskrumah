import { Component, signal } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../core/auth/auth.service';
import { UserRole } from '../../../core/models/user.model';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  form: FormGroup;
  loading = signal(false);
  error = signal('');

  constructor(private fb: FormBuilder, private auth: AuthService, private router: Router) {
    this.form = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required]
    });
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
}
