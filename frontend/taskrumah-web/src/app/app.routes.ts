import { Routes } from '@angular/router';
import { authGuard, adminGuard, childGuard } from './core/auth/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login/login.component').then(m => m.LoginComponent)
  },
  {
    path: 'admin',
    canActivate: [adminGuard],
    loadComponent: () => import('./features/admin/admin-layout/admin-layout.component').then(m => m.AdminLayoutComponent),
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      {
        path: 'dashboard',
        loadComponent: () => import('./features/admin/dashboard/admin-dashboard.component').then(m => m.AdminDashboardComponent)
      },
      {
        path: 'tasks',
        loadComponent: () => import('./features/admin/tasks/admin-tasks.component').then(m => m.AdminTasksComponent)
      },
      {
        path: 'tasks/:id',
        loadComponent: () => import('./features/admin/task-detail/task-detail.component').then(m => m.TaskDetailComponent)
      },
      {
        path: 'rewards',
        loadComponent: () => import('./features/admin/rewards/admin-rewards.component').then(m => m.AdminRewardsComponent)
      },
      {
        path: 'children',
        loadComponent: () => import('./features/admin/children/admin-children.component').then(m => m.AdminChildrenComponent)
      }
    ]
  },
  {
    path: 'child',
    canActivate: [childGuard],
    loadComponent: () => import('./features/child/child-layout/child-layout.component').then(m => m.ChildLayoutComponent),
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      {
        path: 'dashboard',
        loadComponent: () => import('./features/child/dashboard/child-dashboard.component').then(m => m.ChildDashboardComponent)
      },
      {
        path: 'tasks',
        loadComponent: () => import('./features/child/my-tasks/my-tasks.component').then(m => m.MyTasksComponent)
      },
      {
        path: 'tasks/:id/submit',
        loadComponent: () => import('./features/child/task-submit/task-submit.component').then(m => m.TaskSubmitComponent)
      },
      {
        path: 'rewards',
        loadComponent: () => import('./features/child/rewards/child-rewards.component').then(m => m.ChildRewardsComponent)
      },
      {
        path: 'profile',
        loadComponent: () => import('./features/child/profile/child-profile.component').then(m => m.ChildProfileComponent)
      }
    ]
  },
  { path: '**', redirectTo: '/login' }
];

