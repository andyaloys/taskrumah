using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Data;
using TaskRumah.API.DTOs;
using TaskRumah.API.Models;

namespace TaskRumah.API.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly AppDbContext _db;

    public UsersController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var users = await _db.Users
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
            .Where(u => u.Role == UserRole.Child)
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

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateUserRequest req)
    {
        var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var currentRole = User.FindFirstValue(ClaimTypes.Role);

        if (currentRole != "Admin" && currentUserId != id)
            return Forbid();

        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound();

        if (req.Name != null) user.Name = req.Name;
        if (req.AvatarUrl != null) user.AvatarUrl = req.AvatarUrl;

        await _db.SaveChangesAsync();
        return Ok(new UserDto(user.Id, user.Name, user.Email, user.Role, user.AvatarUrl,
            user.TotalPoints, user.CurrentStreak, user.LongestStreak, user.IsActive));
    }
}
