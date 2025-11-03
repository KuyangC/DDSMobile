import React, {
  Component,
} from 'react';

import {
  NativeModules,
  View,
  TouchableWithoutFeedback,
} from 'react-native';

const FullScreen = NativeModules.FullScreen
export default FullScreen;

import debounce from 'debounce';

export class ToggleView extends Component {
  constructor(props,context){
    super(props,context)
    this.state = {
      focus:this.props.focus||true
    }
    this.offFullScreen = debounce(FullScreen.offFullScreen,250);
    this.delayHide = debounce(() => {
        FullScreen.onFullScreen();
        this.setState({focus:false});
    },this.props.delay || 3000);
  }

  handlePress (){
    if(this.state.focus){
      FullScreen.onFullScreen();
      this.setState({focus:!this.state.focus})
    }
    else {
      this.offFullScreen();
      if(this.props.delayHide !== false)
        this.delayHide();
    }
  }

  render() {
    return (
      <TouchableWithoutFeedback
        onPress={this.handlePress.bind(this)}>
        <View style={this.props.style}>
          {React.Children.map(this.props.children, el=>el)}
        </View>
      </TouchableWithoutFeedback>
    );
  }
}
