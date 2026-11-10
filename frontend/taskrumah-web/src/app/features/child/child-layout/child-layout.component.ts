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
    <div class="min-h-screen bg-slate-50 text-slate-800">
      <!-- Top Nav -->
      <header class="bg-white border-b border-slate-200/80 sticky top-0 z-30 shadow-2xs">
        <div class="max-w-md mx-auto px-4 py-2.5 flex items-center justify-between">
          <div class="flex items-center space-x-2.5">
            <div class="w-8 h-8 rounded-xl bg-slate-900 text-white font-bold flex items-center justify-center text-xs shadow-2xs">
              TR
            </div>
            <div>
              <span class="font-bold text-sm tracking-tight text-slate-900 block leading-tight">TaskRumah</span>
              <span class="text-[10px] text-slate-400 font-medium block leading-none">Hai, {{ currentUser()?.name }}</span>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <div class="flex items-center space-x-1 bg-amber-50 text-amber-800 font-bold px-2.5 py-1 rounded-lg text-xs border border-amber-200/80">
              <span class="text-amber-500 text-xs">★</span>
              <span>{{ currentUser()?.totalPoints }}</span>
              <span class="text-[10px] font-medium text-amber-600">poin</span>
            </div>
            <button (click)="logout()" title="Keluar" class="text-slate-400 hover:text-slate-700 p-1.5 rounded-lg hover:bg-slate-100 transition-colors">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
              </svg>
            </button>
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <main class="max-w-md mx-auto px-4 py-5 pb-24">
        <router-outlet></router-outlet>
      </main>

      <!-- Bottom Nav -->
      <nav class="fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-md border-t border-slate-200/80 z-20 shadow-lg">
        <div class="max-w-md mx-auto flex">
          <a routerLink="/child/dashboard" routerLinkActive="text-indigo-600 font-bold"
            class="flex-1 flex flex-col items-center py-2.5 text-slate-400 hover:text-indigo-600 transition-all text-[11px]">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span>Beranda</span>
          </a>
          <a routerLink="/child/tasks" routerLinkActive="text-indigo-600 font-bold"
            class="flex-1 flex flex-col items-center py-2.5 text-slate-400 hover:text-indigo-600 transition-all text-[11px]">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
            </svg>
            <span>Tugasku</span>
          </a>
          <a routerLink="/child/rewards" routerLinkActive="text-indigo-600 font-bold"
            class="flex-1 flex flex-col items-center py-2.5 text-slate-400 hover:text-indigo-600 transition-all text-[11px]">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/>
            </svg>
            <span>Hadiah</span>
          </a>
          <a routerLink="/child/profile" routerLinkActive="text-indigo-600 font-bold"
            class="flex-1 flex flex-col items-center py-2.5 text-slate-400 hover:text-indigo-600 transition-all text-[11px]">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
            </svg>
            <span>Profil</span>
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
