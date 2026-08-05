using System.Collections.Concurrent;

namespace TestAPI.Repositories;

/// <summary>
/// Interface for user authentication operations.
/// </summary>
public interface IAuthRepository
{
    /// <summary>
    /// Gets a user by username or email.
    /// </summary>
    Task<Models.User?> GetUserByUsernameOrEmailAsync(string usernameOrEmail);

    /// <summary>
    /// Gets a user by ID.
    /// </summary>
    Task<Models.User?> GetUserByIdAsync(int id);

    /// <summary>
    /// Creates a new user.
    /// </summary>
    Task<Models.User> CreateUserAsync(Models.User user);

    /// <summary>
    /// Updates the last login date for a user.
    /// </summary>
    Task UpdateLastLoginAsync(int userId);

    /// <summary>
    /// Checks if a username already exists.
    /// </summary>
    Task<bool> UsernameExistsAsync(string username);

    /// <summary>
    /// Checks if an email already exists.
    /// </summary>
    Task<bool> EmailExistsAsync(string email);
}

/// <summary>
/// In-memory user repository for development.
/// Thread-safe using ConcurrentDictionary. Replace with database implementation for production.
/// </summary>
public class AuthRepository : IAuthRepository
{
    private readonly ConcurrentDictionary<int, Models.User> _usersById = new();
    private readonly ConcurrentDictionary<string, Models.User> _usersByUsername = new(StringComparer.OrdinalIgnoreCase);
    private readonly ConcurrentDictionary<string, Models.User> _usersByEmail = new(StringComparer.OrdinalIgnoreCase);
    private int _nextId;

    /// <summary>
    /// Initializes a new instance of the <see cref="AuthRepository"/> class.
    /// Seeds a default admin user for development.
    /// </summary>
    public AuthRepository()
    {
        var admin = new Models.User
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
    public Task<Models.User?> GetUserByUsernameOrEmailAsync(string usernameOrEmail)
    {
        if (_usersByUsername.TryGetValue(usernameOrEmail, out var user))
            return Task.FromResult<Models.User?>(user);
        if (_usersByEmail.TryGetValue(usernameOrEmail, out user))
            return Task.FromResult<Models.User?>(user);
        return Task.FromResult<Models.User?>(null);
    }

    /// <inheritdoc/>
    public Task<Models.User?> GetUserByIdAsync(int id)
    {
        _usersById.TryGetValue(id, out var user);
        return Task.FromResult(user);
    }

    /// <inheritdoc/>
    public Task<Models.User> CreateUserAsync(Models.User user)
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
