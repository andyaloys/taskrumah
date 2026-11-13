import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TaskAssignmentService } from '../../../core/services/task.service';
import { DialogService } from '../../../core/services/dialog.service';
import { TaskAssignment, AssignmentStatus } from '../../../core/models/task-assignment.model';
import { formatLocalDate } from '../../../core/utils/date-utils';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-task-submit',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './task-submit.component.html'
})
export class TaskSubmitComponent implements OnInit {
  assignment = signal<TaskAssignment | null>(null);
  note = '';
  selectedPhoto: File | null = null;
  photoPreview: string | null = null;
  loading = signal(true);
  submitting = signal(false);
  compressing = signal(false);
  compressionInfo = signal<string | null>(null);
  uploadsUrl = environment.uploadsUrl;
  AssignmentStatus = AssignmentStatus;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private assignmentService: TaskAssignmentService,
    private dialog: DialogService
  ) {}

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id')!;
    if (!id || id === '00000000-0000-0000-0000-000000000000') {
      this.loading.set(false);
      this.dialog.error('ID tugas tidak valid. Silakan buka kembali dari daftar tugas.');
      this.router.navigate([this.backUrl()]);
      return;
    }

    this.assignmentService.getAssignment(id).subscribe({
      next: (a) => {
        this.assignment.set(a);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.dialog.error('Gagal memuat tugas atau tugas belum tersedia.');
        this.router.navigate([this.backUrl()]);
      }
    });
  }

  backUrl(): string {
    const from = this.route.snapshot.queryParamMap.get('from');
    return from === 'tasks' ? '/child/tasks' : '/child/dashboard';
  }

  backLabel(): string {
    const from = this.route.snapshot.queryParamMap.get('from');
    return from === 'tasks' ? 'Kembali ke Daftar Tugas' : 'Kembali ke Beranda';
  }

  canModify(): boolean {
    const a = this.assignment();
    if (!a || !a.dueDate) return false;
    const dateStr = formatLocalDate(a.dueDate);
    const [y, m, d] = dateStr.split('-').map(Number);
    const dueDateOnly = new Date(y, m - 1, d);
    const today = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    return dueDateOnly >= yesterday;
  }

  async onPhotoSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files?.[0]) {
      const rawFile = input.files[0];
      const origSize = (rawFile.size / 1024).toFixed(0);

      this.compressing.set(true);
      try {
        const compressed = await this.compressImage(rawFile, 1280, 1280, 0.75);
        this.selectedPhoto = compressed;
        const newSize = (compressed.size / 1024).toFixed(0);
        
        if (compressed.size < rawFile.size) {
          const savedPct = Math.round((1 - (compressed.size / rawFile.size)) * 100);
          this.compressionInfo.set(`${origSize} KB ➔ ${newSize} KB (hemat ${savedPct}%)`);
        } else {
          this.compressionInfo.set(`${newSize} KB`);
        }

        const reader = new FileReader();
        reader.onload = (e) => this.photoPreview = e.target?.result as string;
        reader.readAsDataURL(compressed);
      } catch (err) {
        // Fallback to original file
        this.selectedPhoto = rawFile;
        const reader = new FileReader();
        reader.onload = (e) => this.photoPreview = e.target?.result as string;
        reader.readAsDataURL(rawFile);
      } finally {
        this.compressing.set(false);
      }
    }
  }

  private compressImage(file: File, maxWidth = 1280, maxHeight = 1280, quality = 0.75): Promise<File> {
    return new Promise((resolve) => {
      if (!file.type.startsWith('image/')) {
        resolve(file);
        return;
      }

      const reader = new FileReader();
      reader.onload = (event) => {
        const img = new Image();
        img.onload = () => {
          let width = img.width;
          let height = img.height;

          if (width > maxWidth || height > maxHeight) {
            if (width > height) {
              height = Math.round((height * maxWidth) / width);
              width = maxWidth;
            } else {
              width = Math.round((width * maxHeight) / height);
              height = maxHeight;
            }
          }

          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            resolve(file);
            return;
          }

          ctx.drawImage(img, 0, 0, width, height);
          canvas.toBlob(
            (blob) => {
              if (!blob || blob.size >= file.size) {
                resolve(file);
              } else {
                const cleanName = file.name.replace(/\.[^/.]+$/, '') + '.jpg';
                const compressedFile = new File([blob], cleanName, {
                  type: 'image/jpeg',
                  lastModified: Date.now(),
                });
                resolve(compressedFile);
              }
            },
            'image/jpeg',
            quality
          );
        };
        img.onerror = () => resolve(file);
        img.src = event.target?.result as string;
      };
      reader.onerror = () => resolve(file);
      reader.readAsDataURL(file);
    });
  }

  submit() {
    if (!this.assignment()) return;
    this.submitting.set(true);
    this.assignmentService.submitTask(this.assignment()!.id, this.note, this.selectedPhoto || undefined)
      .subscribe({
        next: () => {
          const from = this.route.snapshot.queryParamMap.get('from');
          if (from === 'tasks') {
            this.router.navigate(['/child/tasks']);
          } else {
            this.router.navigate(['/child/dashboard']);
          }
        },
        error: () => this.submitting.set(false)
      });
  }

  getStatusClass(status: AssignmentStatus): string {
    const classes: Record<AssignmentStatus, string> = {
      [AssignmentStatus.Pending]: 'bg-amber-50 text-amber-700 border border-amber-200/80',
      [AssignmentStatus.Submitted]: 'bg-sky-50 text-sky-700 border border-sky-200/80',
      [AssignmentStatus.Approved]: 'bg-emerald-50 text-emerald-700 border border-emerald-200/80',
      [AssignmentStatus.Rejected]: 'bg-rose-50 text-rose-700 border border-rose-200/80',
      [AssignmentStatus.Late]: 'bg-slate-100 text-slate-600 border border-slate-200/80',
    };
    return classes[status] || 'bg-slate-100 text-slate-700 border border-slate-200/80';
  }

  getStatusLabel(status: AssignmentStatus): string {
    const labels: Record<AssignmentStatus, string> = {
      [AssignmentStatus.Pending]: 'Menunggu',
      [AssignmentStatus.Submitted]: 'Terkirim',
      [AssignmentStatus.Approved]: 'Disetujui',
      [AssignmentStatus.Rejected]: 'Ditolak',
      [AssignmentStatus.Late]: 'Terlambat',
    };
    return labels[status] || status;
  }
}
