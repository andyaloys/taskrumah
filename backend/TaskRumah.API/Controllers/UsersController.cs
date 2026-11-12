using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Common;
using TaskRumah.API.Data;
using TaskRumah.API.DTOs;
using TaskRumah.API.Models;
using TaskRumah.API.Services;

namespace TaskRumah.API.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly FileStorageService _storage;

    public UsersController(AppDbContext db, FileStorageService storage)
    {
        _db = db;
        _storage = storage;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var users = await _db.Users
            .OrderBy(u => u.Role)
            .ThenBy(u => u.Name)
            .Select(u => new UserDto(u.Id, u.Name, u.Email, u.Role, u.AvatarUrl,
                u.TotalPoints, u.CurrentStreak, u.LongestStreak, u.IsActive))
            .ToListAsync();
        return Ok(users);
    }

    [HttpGet("children")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetChildren()
    {
        var users = await _db.Users
            .Where(u => u.Role == UserRole.Child && u.IsActive)
            .OrderBy(u => u.Name)
            .Select(u => new UserDto(u.Id, u.Name, u.Email, u.Role, u.AvatarUrl,
                u.TotalPoints, u.CurrentStreak, u.LongestStreak, u.IsActive))
            .ToListAsync();
        return Ok(users);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var currentRole = User.FindFirstValue(ClaimTypes.Role);

        if (currentRole != "Admin" && currentUserId != id)
            return Forbid();

        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();

        return Ok(new UserDto(user.Id, user.Name, user.Email, user.Role, user.AvatarUrl,
            user.TotalPoints, user.CurrentStreak, user.LongestStreak, user.IsActive));
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateUserRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name) || string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(new { message = "Nama, Email, dan Password wajib diisi" });

        var normalizedEmail = req.Email.Trim().ToLowerInvariant();
        if (await _db.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail))
            return BadRequest(new { message = "Email sudah digunakan oleh akun lain" });

        var newUser = new User
        {
            Id = Guid.NewGuid(),
            Name = req.Name.Trim(),
            Email = normalizedEmail,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            Role = req.Role,
            TotalPoints = 0,
            CurrentStreak = 0,
            LongestStreak = 0,
            LastStreakDate = JakartaTime.Today,
            CreatedAt = JakartaTime.Now,
            IsActive = true
        };

        _db.Users.Add(newUser);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = newUser.Id },
            new UserDto(newUser.Id, newUser.Name, newUser.Email, newUser.Role, newUser.AvatarUrl,
                newUser.TotalPoints, newUser.CurrentStreak, newUser.LongestStreak, newUser.IsActive));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateUserRequest req)
    {
        var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var currentRole = User.FindFirstValue(ClaimTypes.Role);

        if (currentRole != "Admin" && currentUserId != id)
            return Forbid();

        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();

        if (!string.IsNullOrWhiteSpace(req.Name))
            user.Name = req.Name.Trim();

        if (req.AvatarUrl != null)
            user.AvatarUrl = req.AvatarUrl;

        if (!string.IsNullOrWhiteSpace(req.Password))
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password);

        await _db.SaveChangesAsync();
        return Ok(new UserDto(user.Id, user.Name, user.Email, user.Role, user.AvatarUrl,
            user.TotalPoints, user.CurrentStreak, user.LongestStreak, user.IsActive));
    }

    [HttpPost("{id}/avatar")]
    public async Task<IActionResult> UploadAvatar(Guid id, IFormFile file)
    {
        var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var currentRole = User.FindFirstValue(ClaimTypes.Role);

        if (currentRole != "Admin" && currentUserId != id)
            return Forbid();

        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();

        if (file == null || file.Length == 0)
            return BadRequest(new { message = "File gambar tidak boleh kosong" });

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext))
            return BadRequest(new { message = "Format file harus berupa gambar (JPG, PNG, WEBP)" });

        if (file.Length > 10 * 1024 * 1024)
            return BadRequest(new { message = "Ukuran file foto maksimal 10MB" });

        // Clean up previous uploaded avatar file
        if (!string.IsNullOrEmpty(user.AvatarUrl) && user.AvatarUrl.StartsWith("/uploads/avatars/"))
        {
            _storage.DeleteFile(user.AvatarUrl);
        }

        var savedPath = await _storage.SaveFileAsync(file, "uploads/avatars");
        user.AvatarUrl = savedPath;
        await _db.SaveChangesAsync();

        return Ok(new UserDto(user.Id, user.Name, user.Email, user.Role, user.AvatarUrl,
            user.TotalPoints, user.CurrentStreak, user.LongestStreak, user.IsActive));
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        if (currentUserId == id)
            return BadRequest(new { message = "Tidak dapat menonaktifkan akun sendiri" });

        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();

        user.IsActive = false;
        await _db.SaveChangesAsync();
        return Ok(new { message = "Pengguna berhasil dinonaktifkan" });
    }
}
