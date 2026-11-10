using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Data;
using TaskRumah.API.DTOs;
using TaskRumah.API.Services;

namespace TaskRumah.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly JwtService _jwt;

    public AuthController(AppDbContext db, JwtService jwt)
    {
        _db = db;
        _jwt = jwt;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest req)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == req.Email && u.IsActive);
        if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            return Unauthorized(new { message = "Email atau password salah" });

        var token = _jwt.GenerateToken(user);
        return Ok(new LoginResponse(
            token, user.Id, user.Name, user.Email, user.Role, user.AvatarUrl,
            user.TotalPoints, user.CurrentStreak
        ));
    }
}
