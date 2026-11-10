import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { DialogContainerComponent } from './shared/components/dialog-container/dialog-container.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, DialogContainerComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {
  title = 'taskrumah-web';
}
