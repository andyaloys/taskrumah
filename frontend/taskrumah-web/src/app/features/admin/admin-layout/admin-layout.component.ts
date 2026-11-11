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
    <div class="min-h-screen bg-slate-50 flex flex-col md:flex-row text-slate-800">
      <!-- Desktop Sidebar (Hidden on mobile < md) -->
      <aside class="hidden md:flex md:w-64 bg-slate-900 text-slate-300 fixed h-full border-r border-slate-800 z-30 flex-col justify-between">
        <div>
          <!-- Brand Header -->
          <div class="p-5 border-b border-slate-800/80 flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <div class="w-9 h-9 rounded-xl bg-gradient-to-tr from-indigo-500 to-purple-600 flex items-center justify-center text-white shadow-sm font-black tracking-wider text-sm">
                FT
              </div>
              <div>
                <h1 class="font-extrabold text-white text-base tracking-tight">Family<span class="text-indigo-400">Task</span></h1>
                <p class="text-slate-400 text-xs font-medium">Family Management</p>
              </div>
            </div>
          </div>

          <!-- Navigation Links -->
          <nav class="p-3 space-y-1">
            <a routerLink="/admin/dashboard" routerLinkActive="bg-slate-800 text-white font-semibold shadow-sm"
              class="flex items-center space-x-3 px-3.5 py-2.5 rounded-xl hover:bg-slate-800/60 hover:text-white transition-all text-sm font-medium">
              <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
              </svg>
              <span>Dashboard</span>
            </a>

            <a routerLink="/admin/tasks" routerLinkActive="bg-slate-800 text-white font-semibold shadow-sm"
              class="flex items-center space-x-3 px-3.5 py-2.5 rounded-xl hover:bg-slate-800/60 hover:text-white transition-all text-sm font-medium">
              <svg class="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/>
              </svg>
              <span>Kelola Tugas</span>
            </a>

            <a routerLink="/admin/rewards" routerLinkActive="bg-slate-800 text-white font-semibold shadow-sm"
              class="flex items-center space-x-3 px-3.5 py-2.5 rounded-xl hover:bg-slate-800/60 hover:text-white transition-all text-sm font-medium">
              <svg class="w-4 h-4 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/>
              </svg>
              <span>Katalog Hadiah</span>
            </a>

            <a routerLink="/admin/children" routerLinkActive="bg-slate-800 text-white font-semibold shadow-sm"
              class="flex items-center space-x-3 px-3.5 py-2.5 rounded-xl hover:bg-slate-800/60 hover:text-white transition-all text-sm font-medium">
              <svg class="w-4 h-4 text-sky-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
              </svg>
              <span>Data Anak</span>
            </a>
          </nav>
        </div>

        <!-- User profile & Logout footer -->
        <div class="p-4 border-t border-slate-800 bg-slate-900/60">
          <div class="flex items-center space-x-3 mb-3">
            <div class="w-9 h-9 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-sm text-indigo-400">
              {{ currentUser()?.name?.charAt(0) }}
            </div>
            <div class="overflow-hidden">
              <p class="font-semibold text-sm text-white truncate">{{ currentUser()?.name }}</p>
              <p class="text-slate-400 text-xs">Orang Tua / Admin</p>
            </div>
          </div>
          <button (click)="logout()" class="w-full bg-slate-800 hover:bg-rose-950/40 hover:text-rose-400 text-slate-300 font-semibold py-2 px-3 rounded-xl text-xs border border-slate-700/80 hover:border-rose-900/50 transition-all flex items-center justify-center space-x-2 cursor-pointer">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
            </svg>
            <span>Keluar Akun</span>
          </button>
        </div>
      </aside>

      <!-- Mobile Top Header (Visible only on mobile < md) -->
      <header class="md:hidden bg-white border-b border-slate-200/80 sticky top-0 z-30 shadow-2xs">
        <div class="px-4 py-2.5 flex items-center justify-between">
          <div class="flex items-center space-x-2.5">
            <div class="w-8 h-8 rounded-xl bg-indigo-600 text-white font-bold flex items-center justify-center text-xs shadow-2xs">
              TR
            </div>
            <div>
              <span class="font-bold text-sm tracking-tight text-slate-900 block leading-tight">TaskRumah</span>
              <span class="text-[10px] text-slate-500 font-medium block leading-none">Orang Tua • {{ currentUser()?.name }}</span>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <span class="text-[10px] font-bold bg-indigo-50 text-indigo-700 px-2 py-0.5 rounded-md border border-indigo-100">
              Admin
            </span>
            <button (click)="logout()" title="Keluar Akun" class="text-slate-400 hover:text-rose-600 p-1.5 rounded-lg hover:bg-slate-100 transition-colors cursor-pointer">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
              </svg>
            </button>
          </div>
        </div>
      </header>

      <!-- Main Content Area -->
      <main class="flex-1 md:ml-64 p-3.5 sm:p-6 md:p-8 pb-24 md:pb-8 min-h-screen">
        <router-outlet></router-outlet>
      </main>

      <!-- Mobile Bottom Navigation Bar (Visible only on mobile < md, exactly like child app) -->
      <nav class="md:hidden fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-md border-t border-slate-200/80 z-30 shadow-lg">
        <div class="flex">
          <a routerLink="/admin/dashboard" routerLinkActive="text-indigo-600 font-bold"
            class="flex-1 flex flex-col items-center py-2.5 text-slate-400 hover:text-indigo-600 transition-all text-[11px]">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span>Ringkasan</span>
          </a>

          <a routerLink="/admin/tasks" routerLinkActive="text-indigo-600 font-bold"
            class="flex-1 flex flex-col items-center py-2.5 text-slate-400 hover:text-indigo-600 transition-all text-[11px]">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/>
            </svg>
            <span>Tugas</span>
          </a>

          <a routerLink="/admin/rewards" routerLinkActive="text-indigo-600 font-bold"
            class="flex-1 flex flex-col items-center py-2.5 text-slate-400 hover:text-indigo-600 transition-all text-[11px]">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/>
            </svg>
            <span>Hadiah</span>
          </a>

          <a routerLink="/admin/children" routerLinkActive="text-indigo-600 font-bold"
            class="flex-1 flex flex-col items-center py-2.5 text-slate-400 hover:text-indigo-600 transition-all text-[11px]">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
            </svg>
            <span>Anak</span>
          </a>
        </div>
      </nav>
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
