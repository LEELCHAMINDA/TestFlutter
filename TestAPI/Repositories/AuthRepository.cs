using System.Collections.Concurrent;
using TestAPI.Models;

namespace TestAPI.Repositories;

/// <summary>
/// In-memory user repository for development.
/// Thread-safe using ConcurrentDictionary. Replace with database implementation for production.
/// </summary>
public class AuthRepository : IAuthRepository
{
    private readonly ConcurrentDictionary<int, User> _usersById = new();
    private readonly ConcurrentDictionary<string, User> _usersByUsername = new(StringComparer.OrdinalIgnoreCase);
    private readonly ConcurrentDictionary<string, User> _usersByEmail = new(StringComparer.OrdinalIgnoreCase);
    private int _nextId;

    /// <summary>
    /// Initializes a new instance of the <see cref="AuthRepository"/> class.
    /// Seeds a default admin user for development.
    /// </summary>
    public AuthRepository()
    {
        var admin = new User
        {
            Id = Interlocked.Increment(ref _nextId),
            Username = "admin",
            Email = "admin@example.com",
            PasswordHash = HashPassword("Admin123!"),
            FullName = "Administrator",
            IsActive = true,
            CreatedDate = DateTime.UtcNow
        };
        _usersById[admin.Id] = admin;
        _usersByUsername[admin.Username] = admin;
        _usersByEmail[admin.Email] = admin;
    }

    /// <inheritdoc/>
    public Task<User?> GetUserByUsernameOrEmailAsync(string usernameOrEmail)
    {
        if (_usersByUsername.TryGetValue(usernameOrEmail, out var user))
            return Task.FromResult<User?>(user);
        if (_usersByEmail.TryGetValue(usernameOrEmail, out user))
            return Task.FromResult<User?>(user);
        return Task.FromResult<User?>(null);
    }

    /// <inheritdoc/>
    public Task<User?> GetUserByIdAsync(int id)
    {
        _usersById.TryGetValue(id, out var user);
        return Task.FromResult(user);
    }

    /// <inheritdoc/>
    public Task<User> CreateUserAsync(User user)
    {
        user.Id = Interlocked.Increment(ref _nextId);
        user.CreatedDate = DateTime.UtcNow;
        _usersById[user.Id] = user;
        _usersByUsername[user.Username] = user;
        _usersByEmail[user.Email] = user;
        return Task.FromResult(user);
    }

    /// <inheritdoc/>
    public Task UpdateLastLoginAsync(int userId)
    {
        if (_usersById.TryGetValue(userId, out var user))
        {
            user.LastLoginDate = DateTime.UtcNow;
        }
        return Task.CompletedTask;
    }

    /// <inheritdoc/>
    public Task<bool> UsernameExistsAsync(string username)
    {
        return Task.FromResult(_usersByUsername.ContainsKey(username));
    }

    /// <inheritdoc/>
    public Task<bool> EmailExistsAsync(string email)
    {
        return Task.FromResult(_usersByEmail.ContainsKey(email));
    }

    /// <summary>
    /// Hashes a password using BCrypt with per-user random salt.
    /// </summary>
    public static string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password);
    }

    /// <summary>
    /// Verifies a password against a BCrypt hash.
    /// </summary>
    public static bool VerifyPassword(string password, string hash)
    {
        return BCrypt.Net.BCrypt.Verify(password, hash);
    }
}
