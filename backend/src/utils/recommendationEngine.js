class RecommendationEngine {
  constructor() {
    this.similarityThreshold = 0.3;
  }

  // Collaborative filtering based on user purchase history
  async getCollaborativeRecommendations(userId, userPurchases, allProducts) {
    // Find similar users based on purchase history
    const similarUsers = await this.findSimilarUsers(userId, userPurchases);
    
    // Get products purchased by similar users but not by current user
    const recommendations = [];
    for (const user of similarUsers) {
      for (const purchase of user.purchases) {
        if (!userPurchases.includes(purchase.productId)) {
          recommendations.push(purchase.productId);
        }
      }
    }
    
    // Get unique recommendations
    return [...new Set(recommendations)];
  }

  // Content-based filtering
  getContentBasedRecommendations(userPreferences, allProducts) {
    const scoredProducts = allProducts.map(product => {
      let score = 0;
      
      // Match based on categories
      if (userPreferences.categories.includes(product.category)) {
        score += 0.3;
      }
      
      // Match based on brands
      if (userPreferences.brands.includes(product.brand)) {
        score += 0.2;
      }
      
      // Match based on price range
      if (product.price >= userPreferences.minPrice && 
          product.price <= userPreferences.maxPrice) {
        score += 0.2;
      }
      
      // Match based on tags
      const commonTags = product.tags.filter(tag => 
        userPreferences.tags.includes(tag)
      ).length;
      score += (commonTags / product.tags.length) * 0.3;
      
      return { product, score };
    });
    
    return scoredProducts
      .sort((a, b) => b.score - a.score)
      .slice(0, 10)
      .map(item => item.product);
  }

  // Size recommendation based on measurements
  recommendSize(measurements, productType) {
    const { height, weight, chest, waist, hips } = measurements;
    
    if (productType === 'top') {
      if (chest < 34) return 'XS';
      if (chest < 36) return 'S';
      if (chest < 38) return 'M';
      if (chest < 40) return 'L';
      if (chest < 42) return 'XL';
      return 'XXL';
    } else if (productType === 'bottom') {
      if (waist < 28) return 'XS';
      if (waist < 30) return 'S';
      if (waist < 32) return 'M';
      if (waist < 34) return 'L';
      if (waist < 36) return 'XL';
      return 'XXL';
    }
    
    return 'M'; // Default
  }

  // Find similar users (simplified)
  async findSimilarUsers(userId, userPurchases) {
    // This would query the database for users with similar purchase patterns
    // For now, return empty array
    return [];
  }
}

module.exports = new RecommendationEngine();