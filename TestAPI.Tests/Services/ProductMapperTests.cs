using FluentAssertions;
using TestAPI.Models;
using TestAPI.Models.Dtos;
using TestAPI.Services;

namespace TestAPI.Tests.Services;

public class ProductMapperTests
{
    private readonly ProductMapper _mapper = new();

    [Fact]
    public void ToResponse_ShouldMapAllFieldsCorrectly()
    {
        // Arrange
        var product = new Product
        {
            Id = 1,
            Name = "Test Product",
            Price = 29.99m,
            Description = "Test Description",
            Stock = 100,
            IsActive = true,
            CreatedDate = new DateTime(2024, 1, 15, 10, 30, 0)
        };

        // Act
        var result = _mapper.ToResponse(product);

        // Assert
        result.Id.Should().Be(1);
        result.Name.Should().Be("Test Product");
        result.Price.Should().Be(29.99m);
        result.Description.Should().Be("Test Description");
        result.Stock.Should().Be(100);
        result.IsActive.Should().BeTrue();
        result.CreatedDate.Should().Be(new DateTime(2024, 1, 15, 10, 30, 0));
    }

    [Fact]
    public void ToResponse_ShouldHandleNullOptionalFields()
    {
        // Arrange
        var product = new Product
        {
            Id = 2,
            Name = null,
            Price = 0,
            Description = null,
            Stock = 0,
            IsActive = false,
            CreatedDate = DateTime.MinValue
        };

        // Act
        var result = _mapper.ToResponse(product);

        // Assert
        result.Id.Should().Be(2);
        result.Name.Should().BeNull();
        result.Description.Should().BeNull();
    }

    [Fact]
    public void ToDomain_FromCreateRequest_ShouldMapAllFields()
    {
        // Arrange
        var request = new CreateProductRequest(
            Name: "New Product",
            Price: 49.99m,
            Description: "New Description",
            Stock: 50,
            IsActive: true
        );

        // Act
        var result = _mapper.ToDomain(request);

        // Assert
        result.Id.Should().Be(0);
        result.Name.Should().Be("New Product");
        result.Price.Should().Be(49.99m);
        result.Description.Should().Be("New Description");
        result.Stock.Should().Be(50);
        result.IsActive.Should().BeTrue();
        result.CreatedDate.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
    }

    [Fact]
    public void ToDomain_FromUpdateRequest_ShouldMapAllFieldsIncludingId()
    {
        // Arrange
        var request = new UpdateProductRequest(
            Name: "Updated Product",
            Price: 99.99m,
            Description: "Updated Description",
            Stock: 25,
            IsActive: false
        );

        // Act
        var result = _mapper.ToDomain(request, 42);

        // Assert
        result.Id.Should().Be(42);
        result.Name.Should().Be("Updated Product");
        result.Price.Should().Be(99.99m);
        result.Description.Should().Be("Updated Description");
        result.Stock.Should().Be(25);
        result.IsActive.Should().BeFalse();
    }

    [Fact]
    public void ToDomain_FromUpdateRequest_ShouldNotSetCreatedDate()
    {
        // Arrange
        var request = new UpdateProductRequest(
            Name: "Product",
            Price: 10m,
            Description: null,
            Stock: 5,
            IsActive: true
        );

        // Act
        var result = _mapper.ToDomain(request, 1);

        // Assert
        result.CreatedDate.Should().Be(default(DateTime));
    }
}
