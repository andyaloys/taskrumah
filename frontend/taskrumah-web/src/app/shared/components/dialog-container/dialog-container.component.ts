import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DialogService, ToastItem } from '../../../core/services/dialog.service';

@Component({
  selector: 'app-dialog-container',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dialog-container.component.html'
})
export class DialogContainerComponent {
  constructor(public dialog: DialogService) {}

  getToastBg(type: ToastItem['type']): string {
    switch (type) {
      case 'success': return 'bg-emerald-50 text-emerald-900 border-emerald-200/90 shadow-emerald-900/5';
      case 'error': return 'bg-rose-50 text-rose-900 border-rose-200/90 shadow-rose-900/5';
      case 'warning': return 'bg-amber-50 text-amber-900 border-amber-200/90 shadow-amber-900/5';
      case 'info': return 'bg-sky-50 text-sky-900 border-sky-200/90 shadow-sky-900/5';
    }
  }

  getToastIconColor(type: ToastItem['type']): string {
    switch (type) {
      case 'success': return 'text-emerald-600 bg-emerald-100';
      case 'error': return 'text-rose-600 bg-rose-100';
      case 'warning': return 'text-amber-600 bg-amber-100';
      case 'info': return 'text-sky-600 bg-sky-100';
    }
  }
}
