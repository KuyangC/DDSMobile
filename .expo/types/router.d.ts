/* eslint-disable */
import * as Router from 'expo-router';

export * from 'expo-router';

declare module 'expo-router' {
  export namespace ExpoRouter {
    export interface __routes<T extends string | object = string> {
      hrefInputParams: { pathname: Router.RelativePathString, params?: Router.UnknownInputParams } | { pathname: Router.ExternalPathString, params?: Router.UnknownInputParams } | { pathname: `/`; params?: Router.UnknownInputParams; } | { pathname: `/_sitemap`; params?: Router.UnknownInputParams; } | { pathname: `/mainPage/areaTable`; params?: Router.UnknownInputParams; } | { pathname: `/mainPage/navbar`; params?: Router.UnknownInputParams; } | { pathname: `/settingsPage/settingDetail`; params?: Router.UnknownInputParams; } | { pathname: `/settingsPage/settings`; params?: Router.UnknownInputParams; };
      hrefOutputParams: { pathname: Router.RelativePathString, params?: Router.UnknownOutputParams } | { pathname: Router.ExternalPathString, params?: Router.UnknownOutputParams } | { pathname: `/`; params?: Router.UnknownOutputParams; } | { pathname: `/_sitemap`; params?: Router.UnknownOutputParams; } | { pathname: `/mainPage/areaTable`; params?: Router.UnknownOutputParams; } | { pathname: `/mainPage/navbar`; params?: Router.UnknownOutputParams; } | { pathname: `/settingsPage/settingDetail`; params?: Router.UnknownOutputParams; } | { pathname: `/settingsPage/settings`; params?: Router.UnknownOutputParams; };
      href: Router.RelativePathString | Router.ExternalPathString | `/${`?${string}` | `#${string}` | ''}` | `/_sitemap${`?${string}` | `#${string}` | ''}` | `/mainPage/areaTable${`?${string}` | `#${string}` | ''}` | `/mainPage/navbar${`?${string}` | `#${string}` | ''}` | `/settingsPage/settingDetail${`?${string}` | `#${string}` | ''}` | `/settingsPage/settings${`?${string}` | `#${string}` | ''}` | { pathname: Router.RelativePathString, params?: Router.UnknownInputParams } | { pathname: Router.ExternalPathString, params?: Router.UnknownInputParams } | { pathname: `/`; params?: Router.UnknownInputParams; } | { pathname: `/_sitemap`; params?: Router.UnknownInputParams; } | { pathname: `/mainPage/areaTable`; params?: Router.UnknownInputParams; } | { pathname: `/mainPage/navbar`; params?: Router.UnknownInputParams; } | { pathname: `/settingsPage/settingDetail`; params?: Router.UnknownInputParams; } | { pathname: `/settingsPage/settings`; params?: Router.UnknownInputParams; };
    }
  }
}
