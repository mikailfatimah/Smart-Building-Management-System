# Smart Building Management System

A comprehensive blockchain-based building management system built on Stacks using Clarity smart contracts. This system automates and secures various aspects of building operations including energy management, access control, maintenance scheduling, tenant management, and emergency protocols.

## System Overview

The Smart Building Management System consists of five interconnected smart contracts:

### 1. Energy Consumption Optimization Contract
- **Purpose**: Reduces utility costs through automated energy management
- **Features**:
    - Real-time energy consumption tracking
    - Automated optimization recommendations
    - Cost calculation and billing
    - Energy efficiency scoring
    - Peak usage alerts

### 2. Access Control Management Contract
- **Purpose**: Secures building entry and room access
- **Features**:
    - Role-based access permissions
    - Time-restricted access controls
    - Access logging and audit trails
    - Emergency override capabilities
    - Guest access management

### 3. Maintenance Scheduling Contract
- **Purpose**: Coordinates repair and upkeep activities
- **Features**:
    - Preventive maintenance scheduling
    - Work order management
    - Contractor assignment and tracking
    - Equipment lifecycle monitoring
    - Maintenance cost tracking

### 4. Tenant Lease Management Contract
- **Purpose**: Automates rental agreements and payments
- **Features**:
    - Lease agreement storage and management
    - Automated rent collection
    - Security deposit handling
    - Lease renewal notifications
    - Payment history tracking

### 5. Emergency Evacuation Contract
- **Purpose**: Manages safety protocols during disasters
- **Features**:
    - Emergency alert broadcasting
    - Evacuation route management
    - Personnel accountability tracking
    - Emergency contact notifications
    - Post-emergency reporting

## Architecture

Each contract operates independently while maintaining data consistency through standardized interfaces. The system uses Clarity's built-in security features to ensure data integrity and access control.

### Key Design Principles

1. **Security First**: All contracts implement robust access controls and input validation
2. **Transparency**: All operations are logged and auditable on the blockchain
3. **Efficiency**: Optimized for minimal transaction costs and fast execution
4. **Scalability**: Designed to handle multiple buildings and thousands of users
5. **Compliance**: Built with regulatory requirements in mind

## Getting Started

### Prerequisites

- Clarinet CLI installed
- Node.js 18+ for testing
- Stacks wallet for deployment

### Installation

\`\`\`bash
git clone <repository-url>
cd smart-building-management
npm install
\`\`\`

### Testing

Run the comprehensive test suite:

\`\`\`bash
npm test
\`\`\`

### Deployment

Deploy contracts to testnet:

\`\`\`bash
clarinet deployments apply --devnet
\`\`\`

## Contract Specifications

### Data Types

- **Building ID**: `uint` - Unique identifier for each building
- **User Principal**: `principal` - Stacks address for users
- **Timestamps**: `uint` - Block height for time-based operations
- **Access Levels**: `uint` - Numerical access permission levels
- **Energy Units**: `uint` - Standardized energy consumption units

### Error Codes

All contracts use standardized error codes:
- `u100-u199`: Permission and access errors
- `u200-u299`: Data validation errors
- `u300-u399`: State management errors
- `u400-u499`: Business logic errors
- `u500-u599`: System errors

## Security Considerations

- All functions validate caller permissions
- Input sanitization prevents malicious data
- State changes are atomic and reversible
- Emergency functions have additional safeguards
- Regular security audits recommended

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
