import { Component, OnInit, signal } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../core/auth/auth.service';
import { NotificationService } from '../../../core/services/notification.service';

@Component({
  selector: 'app-child-layout',
  standalone: true,
  imports: [RouterOutlet, CommonModule, RouterLink, RouterLinkActive],
  template: `
    <div class="min-h-screen bg-gradient-to-br from-purple-50 to-indigo-50">
      <!-- Top Nav -->
      <header class="bg-white shadow-sm sticky top-0 z-10">
        <div class="max-w-lg mx-auto px-4 py-3 flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <span class="text-2xl">🏠</span>
            <span class="font-black text-xl text-purple-700">TaskRumah</span>
          </div>
          <div class="flex items-center space-x-3">
            <div class="text-right">
              <p class="text-sm font-black text-gray-800">{{ currentUser()?.name }}</p>
              <p class="text-xs text-yellow-600 font-bold">⭐ {{ currentUser()?.totalPoints }} poin</p>
            </div>
            <button (click)="logout()" class="bg-gray-100 hover:bg-gray-200 text-gray-600 p-2 rounded-xl text-sm font-bold">🚪</button>
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <main class="max-w-lg mx-auto px-4 py-6 pb-24">
        <router-outlet></router-outlet>
      </main>

      <!-- Bottom Nav -->
      <nav class="fixed bottom-0 left-0 right-0 bg-white border-t-2 border-gray-100 shadow-xl">
        <div class="max-w-lg mx-auto flex">
          <a routerLink="/child/dashboard" routerLinkActive="text-purple-600"
            class="flex-1 flex flex-col items-center py-3 text-gray-400 hover:text-purple-600 transition-all">
            <span class="text-2xl">🏠</span>
            <span class="text-xs font-bold mt-1">Beranda</span>
          </a>
          <a routerLink="/child/tasks" routerLinkActive="text-purple-600"
            class="flex-1 flex flex-col items-center py-3 text-gray-400 hover:text-purple-600 transition-all">
            <span class="text-2xl">📋</span>
            <span class="text-xs font-bold mt-1">Tugasku</span>
          </a>
          <a routerLink="/child/rewards" routerLinkActive="text-purple-600"
            class="flex-1 flex flex-col items-center py-3 text-gray-400 hover:text-purple-600 transition-all">
            <span class="text-2xl">🎁</span>
            <span class="text-xs font-bold mt-1">Hadiah</span>
          </a>
          <a routerLink="/child/profile" routerLinkActive="text-purple-600"
            class="flex-1 flex flex-col items-center py-3 text-gray-400 hover:text-purple-600 transition-all">
            <span class="text-2xl">👤</span>
            <span class="text-xs font-bold mt-1">Profil</span>
          </a>
        </div>
      </nav>
    </div>
  `
})
export class ChildLayoutComponent {
  currentUser;

  constructor(private auth: AuthService) {
    this.currentUser = this.auth.currentUser;
  }

  logout() {
    this.auth.logout();
  }
}
