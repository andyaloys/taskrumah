import { Injectable, signal } from '@angular/core';

export interface ToastItem {
  id: string;
  message: string;
  type: 'success' | 'error' | 'info' | 'warning';
  duration: number;
}

export interface ConfirmDialogOptions {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  type?: 'primary' | 'danger' | 'warning';
  icon?: string;
  resolve?: (value: boolean) => void;
}

export interface PromptDialogOptions {
  title: string;
  message?: string;
  placeholder?: string;
  defaultValue?: string;
  confirmText?: string;
  cancelText?: string;
  type?: 'primary' | 'danger' | 'warning';
  icon?: string;
  resolve?: (value: string | null) => void;
}

@Injectable({
  providedIn: 'root'
})
export class DialogService {
  toasts = signal<ToastItem[]>([]);
  activeConfirm = signal<ConfirmDialogOptions | null>(null);
  activePrompt = signal<PromptDialogOptions | null>(null);
  promptValue = signal<string>('');

  toast(message: string, type: 'success' | 'error' | 'info' | 'warning' = 'success', duration = 3500) {
    const id = Math.random().toString(36).substring(2, 9);
    const item: ToastItem = { id, message, type, duration };
    this.toasts.update(list => [...list, item]);

    if (duration > 0) {
      setTimeout(() => {
        this.removeToast(id);
      }, duration);
    }
  }

  success(message: string, duration = 3500) {
    this.toast(message, 'success', duration);
  }

  error(message: string, duration = 4000) {
    this.toast(message, 'error', duration);
  }

  warning(message: string, duration = 3500) {
    this.toast(message, 'warning', duration);
  }

  info(message: string, duration = 3500) {
    this.toast(message, 'info', duration);
  }

  removeToast(id: string) {
    this.toasts.update(list => list.filter(t => t.id !== id));
  }

  confirm(options: {
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    type?: 'primary' | 'danger' | 'warning';
    icon?: string;
  }): Promise<boolean> {
    return new Promise((resolve) => {
      this.activeConfirm.set({
        ...options,
        confirmText: options.confirmText || 'Ya, Lanjutkan',
        cancelText: options.cancelText || 'Batal',
        type: options.type || 'primary',
        resolve
      });
    });
  }

  handleConfirm(result: boolean) {
    const dialog = this.activeConfirm();
    if (dialog && dialog.resolve) {
      dialog.resolve(result);
    }
    this.activeConfirm.set(null);
  }

  prompt(options: {
    title: string;
    message?: string;
    placeholder?: string;
    defaultValue?: string;
    confirmText?: string;
    cancelText?: string;
    type?: 'primary' | 'danger' | 'warning';
    icon?: string;
  }): Promise<string | null> {
    return new Promise((resolve) => {
      this.promptValue.set(options.defaultValue || '');
      this.activePrompt.set({
        ...options,
        confirmText: options.confirmText || 'Kirim',
        cancelText: options.cancelText || 'Batal',
        type: options.type || 'primary',
        resolve
      });
    });
  }

  handlePrompt(submit: boolean) {
    const dialog = this.activePrompt();
    if (dialog && dialog.resolve) {
      dialog.resolve(submit ? this.promptValue() : null);
    }
    this.activePrompt.set(null);
    this.promptValue.set('');
  }
}
