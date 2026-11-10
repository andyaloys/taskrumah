import { Component, OnInit, signal } from '@angular/core';
import { RouterOutlet, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../../../core/auth/auth.service';
import { NotificationService } from '../../../core/services/notification.service';

@Component({
  selector: 'app-admin-layout',
  standalone: true,
  imports: [RouterOutlet, CommonModule, RouterLink, RouterLinkActive],
  template: `
    <div class="min-h-screen bg-gray-50 flex">
      <!-- Sidebar -->
      <aside class="w-64 bg-gradient-to-b from-purple-700 to-indigo-800 text-white fixed h-full shadow-xl z-10">
        <div class="p-6 border-b border-purple-600">
          <div class="flex items-center space-x-3">
            <span class="text-3xl">🏠</span>
            <div>
              <h1 class="font-black text-xl">TaskRumah</h1>
              <p class="text-purple-200 text-sm">Panel Admin</p>
            </div>
          </div>
        </div>

        <nav class="p-4 space-y-2">
          <a routerLink="/admin/dashboard" routerLinkActive="bg-white/20"
            class="flex items-center space-x-3 px-4 py-3 rounded-2xl hover:bg-white/10 transition-all font-semibold">
            <span class="text-xl">📊</span><span>Dashboard</span>
          </a>
          <a routerLink="/admin/tasks" routerLinkActive="bg-white/20"
            class="flex items-center space-x-3 px-4 py-3 rounded-2xl hover:bg-white/10 transition-all font-semibold">
            <span class="text-xl">📋</span><span>Tugas</span>
          </a>
          <a routerLink="/admin/rewards" routerLinkActive="bg-white/20"
            class="flex items-center space-x-3 px-4 py-3 rounded-2xl hover:bg-white/10 transition-all font-semibold">
            <span class="text-xl">🎁</span><span>Hadiah</span>
          </a>
          <a routerLink="/admin/children" routerLinkActive="bg-white/20"
            class="flex items-center space-x-3 px-4 py-3 rounded-2xl hover:bg-white/10 transition-all font-semibold">
            <span class="text-xl">👨‍👧‍👦</span><span>Anak-anak</span>
          </a>
        </nav>

        <div class="absolute bottom-0 left-0 right-0 p-4 border-t border-purple-600">
          <div class="flex items-center space-x-3 mb-3">
            <div class="w-10 h-10 rounded-full bg-purple-500 flex items-center justify-center font-bold text-lg">
              {{ currentUser()?.name?.charAt(0) }}
            </div>
            <div>
              <p class="font-bold text-sm">{{ currentUser()?.name }}</p>
              <p class="text-purple-300 text-xs">Admin</p>
            </div>
          </div>
          <button (click)="logout()" class="w-full bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded-xl text-sm transition-all">
            🚪 Keluar
          </button>
        </div>
      </aside>

      <!-- Main Content -->
      <main class="ml-64 flex-1 p-8">
        <router-outlet></router-outlet>
      </main>
    </div>
  `
})
export class AdminLayoutComponent implements OnInit {
  currentUser;
  unreadCount = signal(0);

  constructor(private auth: AuthService, private notifService: NotificationService, private router: Router) {
    this.currentUser = this.auth.currentUser;
  }

  ngOnInit() {
    this.loadUnreadCount();
  }

  loadUnreadCount() {
    this.notifService.getUnreadCount().subscribe(r => this.unreadCount.set(r.count));
  }

  logout() {
    this.auth.logout();
  }
}
