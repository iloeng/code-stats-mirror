/**
 * A data request to be sent to the backend profile GraphQL API.
 *
 * Specific data requests should inherit from this class and implement the methods.
 */
class DataRequest {
  // Convert this request to a string that can be sent to the API
  toAPI() {
    throw new Error('Method not implemented');
  }

  // Compare this request to another request, to determine if they are equivalent. This is used to determine if instead
  // of sending both requests, only one of them could be sent and the same data be given to both components.
  compare() {
    throw new Error('Method not implemented');
  }
}

export default DataRequest;
